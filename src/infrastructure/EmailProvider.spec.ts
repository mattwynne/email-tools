import { Email } from "../core/Email"
import { MailboxState } from "../core/MailboxState"
import { Mailbox } from "../core/Mailbox"
import { EmailAddress } from "../core/EmailAddress"
import { MailboxName } from "../core/MailboxName"
import { EmailProvider, FastmailConfig, FastmailSession } from "./EmailProvider"
import { assertThat, equalTo } from "hamjest"
import { EmailSubject } from "../core/EmailSubject"

describe(EmailProvider.name, () => {
  describe("null mode", () => {
    it("can be created with a stubbed MailboxState", async () => {
      const mailboxState = new MailboxState([
        new Mailbox(MailboxName.of("Inbox/Paperwork"), [
          Email.from(EmailAddress.of("someone@example.com")).about(
            EmailSubject.of("a subject")
          ),
        ]),
      ])
      const provider = EmailProvider.createNull({ mailboxState })
      const actual = await provider.getMailboxState()
      assertThat(actual, equalTo(mailboxState))
    })

    it("returns only mailboxes matching the given names", async () => {
      const mailboxState = new MailboxState([
        new Mailbox(MailboxName.of("Inbox/Paperwork"), []),
        new Mailbox(MailboxName.of("Inbox/Screener"), []),
        new Mailbox(MailboxName.of("Sent"), []),
      ])
      const provider = EmailProvider.createNull({ mailboxState })
      const actual = await provider.getMailboxState([
        MailboxName.of("Inbox/Paperwork"),
        MailboxName.of("Inbox/Screener"),
      ])
      assertThat(
        actual,
        equalTo(
          new MailboxState([
            new Mailbox(MailboxName.of("Inbox/Paperwork"), []),
            new Mailbox(MailboxName.of("Inbox/Screener"), []),
          ])
        )
      )
    })
  })

  describe("fastmail mode", function () {
    this.timeout(10000)
    const fastmailConfig: FastmailConfig = {
      token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
    }

    it("connects to a real fastmail inbox", async function () {
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
