import { assertThat, equalTo } from "hamjest"
import nodemailer from "nodemailer"
import { eventually } from "ts-eventually"
import { EmailProvider } from "./EmailProvider"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import {
  MailboxState,
  Mailbox,
  Email,
  EmailAddress,
  EmailSubject,
  MailboxName,
} from "../../Core"

describe(EmailProvider.name, () => {
  describe("null mode", () => {
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
      const provider = EmailProvider.createNull({
        mailboxStates,
      })
      assertThat(
        [await provider.getMailboxState(), await provider.getMailboxState()],
        equalTo(mailboxStates)
      )
    })

    it("can return only mailboxes matching the given names", async () => {
      const mailboxState = new MailboxState([
        Mailbox.named("Inbox/Paperwork"),
        Mailbox.named("Inbox/Screener"),
        Mailbox.named("Sent"),
      ])
      const provider = EmailProvider.createNull({
        mailboxStates: [mailboxState],
      })
      const actual = await provider.getMailboxState([
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
    this.timeout(process.env.SLOW_TEST_TIMEOUT || 10000)

    const fastmailConfig: FastmailConfig = {
      token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
    }

    it("connects to a real, empty fastmail inbox", async function () {
      await reset(fastmailConfig.token)
      const provider = await EmailProvider.create(fastmailConfig)
      assertThat(
        await provider.getMailboxState(),
        equalTo(
          new MailboxState([
            Mailbox.named("Inbox"),
            Mailbox.named("Archive"),
            Mailbox.named("Drafts"),
            Mailbox.named("Sent"),
            Mailbox.named("Spam"),
            Mailbox.named("Trash"),
          ])
        )
      )
    })

    it("reads an email that's in the Inbox", async () => {
      await reset(fastmailConfig.token)
      await sendTestEmail(
        Email.from(EmailAddress.of("someone@example.com")).about(
          EmailSubject.of("a subject")
        )
      )
      const provider = await EmailProvider.create(fastmailConfig)
      await eventually(async () =>
        assertThat(
          await provider.getMailboxState([MailboxName.of("Inbox")]),
          equalTo(
            new MailboxState([
              Mailbox.named("Inbox").withEmails([
                Email.from(EmailAddress.of("someone@example.com")).about(
                  EmailSubject.of("a subject")
                ),
              ]),
            ])
          )
        )
      )
    })

    it("fetches only specific mailboxes", async () => {
      await reset(fastmailConfig.token)
      const provider = await EmailProvider.create(fastmailConfig)
      assertThat(
        await provider.getMailboxState([
          MailboxName.of("Inbox"),
          MailboxName.of("Archive"),
        ]),
        equalTo(
          new MailboxState([Mailbox.named("Inbox"), Mailbox.named("Archive")])
        )
      )
    })
  })
})

const reset = async (token: string) => {
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
  const smtp = nodemailer.createTransport({
    host: "smtp.fastmail.com",
    port: 465,
    secure: true,
    auth: {
      user: "test@levain.codes",
      pass: process.env.FASTMAIL_SMTP_PASSWORD,
    },
  })
  await smtp.sendMail({
    to: "test@levain.codes",
    from: email.from.value,
    subject: email.subject.value,
  })
}