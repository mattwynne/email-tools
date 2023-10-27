import { assertThat, equalTo, is, truthy } from "hamjest"
import nodemailer from "nodemailer"
import { eventually } from "ts-eventually"
import { FastmailAccount } from "./FastmailAccount"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import {
  MailboxState,
  Mailbox,
  Email,
  EmailAddress,
  EmailSubject,
  MailboxName,
} from "../../core"
import Mail from "nodemailer/lib/mailer"

describe(FastmailAccount.name, () => {
  describe.skip("null mode", () => {
    it("can be created with stubbed MailboxStates", async () => {
      const mailboxStates = [
        new MailboxState([
          Mailbox.named("Inbox/Screener").withEmails([
            Email.from(EmailAddress.of("someone@example.com")).about(
              EmailSubject.of("a subject")
            ),
          ]),
        ]),
        new MailboxState([
          Mailbox.named("Inbox/Paperwork").withEmails([
            Email.from(EmailAddress.of("someone@example.com")).about(
              EmailSubject.of("a subject")
            ),
          ]),
        ]),
      ]
      const provider = FastmailAccount.createNull({
        mailboxStates,
      })
      assertThat(
        [await provider.refresh(), await provider.refresh()],
        equalTo(mailboxStates)
      )
    })

    it("can return only mailboxes matching the given names", async () => {
      const mailboxState = new MailboxState([
        Mailbox.named("Inbox/Paperwork"),
        Mailbox.named("Inbox/Screener"),
        Mailbox.named("Sent"),
      ])
      const account = FastmailAccount.createNull({
        mailboxStates: [mailboxState],
      })
      const actual = await account.state.of([
        MailboxName.of("Inbox/Paperwork"),
        MailboxName.of("Inbox/Screener"),
      ])
      assertThat(
        actual,
        equalTo(
          new MailboxState([
            Mailbox.named("Inbox/Paperwork"),
            Mailbox.named("Inbox/Screener"),
          ])
        )
      )
    })
  })

  describe("fastmail mode @online", function () {
    this.timeout(process.env.SLOW_TEST_TIMEOUT || 30000)

    const config: FastmailConfig = {
      token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
    }

    this.beforeEach(() => reset(config))

    it("connects to a real, empty fastmail inbox", async function () {
      await FastmailAccount.connect(config, async (account) => {
        assertThat(
          account.state.mailboxes.map((mailbox) => mailbox.name),
          equalTo([
            MailboxName.of("Inbox"),
            MailboxName.of("Archive"),
            MailboxName.of("Drafts"),
            MailboxName.of("Sent"),
            MailboxName.of("Spam"),
            MailboxName.of("Trash"),
          ])
        )
      })
    })

    it("counts emails in a mailbox", async () => {
      await sendTestEmail(
        Email.from("someone@example.com").about(EmailSubject.of("a subject"))
      )
      await FastmailAccount.connect(config, async (account) => {
        await eventually(async () => {
          assertThat(
            await account.state.of([MailboxName.of("Inbox")]).mailboxes[0]
              .emails.length,
            equalTo(1)
          )
          await account.refresh()
        })
      })
    })

    it("reads emails in a mailbox", async () => {
      await sendTestEmail(
        Email.from("someone@example.com").about(EmailSubject.of("a subject"))
      )
      await FastmailAccount.connect(config, async (account) => {
        await eventually(async () =>
          assertThat(
            await account.emailsIn(MailboxName.of("Inbox")),
            equalTo([
              Email.from("someone@example.com").about(
                EmailSubject.of("a subject")
              ),
            ])
          )
        )
      })
    })

    it("emits events when a new mail arrives", async () => {
      let eventReceived = false
      await FastmailAccount.connect(config, async (account) => {
        await account.onChange(() => {
          eventReceived = true
        })

        await sendTestEmail(
          Email.from(EmailAddress.of("someone@example.com")).about(
            EmailSubject.of("a subject")
          )
        )
      })
      await eventually(async () => assertThat(eventReceived, is(truthy())))
    })
  })
})

const reset = async ({ token }: FastmailConfig) => {
  const api = await FastmailSession.create(token)
  if (api.username !== "test@levain.codes") {
    throw new Error(
      `Only run the tests with the test account! Attempted to run with ${api.username}`
    )
  }
  await api.calls([
    [
      "Email/query",
      {
        accountId: api.accountId,
        filter: null,
      },
      "0",
    ],
    [
      "Email/set",
      {
        accountId: api.accountId,
        "#destroy": {
          resultOf: "0",
          name: "Email/query",
          path: "/ids",
        },
      },
      "1",
    ],
    [
      "Mailbox/query",
      {
        accountId: api.accountId,
        filter: {
          hasAnyRole: false,
        },
      },
      "2",
    ],
    [
      "Mailbox/set",
      {
        accountId: api.accountId,
        "#destroy": {
          resultOf: "2",
          name: "Mailbox/query",
          path: "/ids",
        },
      },
      "3",
    ],
  ])
}

async function sendTestEmail(email: Email) {
  const pass = process.env.FASTMAIL_SMTP_PASSWORD
  if (!pass) throw new Error("please set FASTMAIL_SMTP_PASSWORD")
  const smtp = nodemailer.createTransport({
    host: "smtp.fastmail.com",
    port: 465,
    secure: true,
    auth: {
      user: "test@levain.codes",
      pass,
    },
  })
  await smtp.sendMail({
    to: "test@levain.codes",
    from: email.from.value,
    subject: email.subject.value,
  })
}
