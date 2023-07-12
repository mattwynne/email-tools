import { Email } from "../core/Email"
import { MailboxState } from "../core/MailboxState"
import { Mailbox } from "../core/Mailbox"
import { EmailAddress } from "../core/EmailAddress"
import { MailboxName } from "../core/MailboxName"
import { EmailProvider, FastmailConfig, FastmailSession } from "./EmailProvider"
import { assertThat, equalTo } from "hamjest"
import util from "util"
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
  })

  describe("fastmail mode", () => {
    it("connects to a real fastmail inbox", async function () {
      this.timeout(10000)
      const fastmailConfig: FastmailConfig = {
        token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
      }
      await deleteAllEmails(fastmailConfig.token)
      const provider = await EmailProvider.create(fastmailConfig)
      renderMailboxState(await provider.getMailboxState())
    })
  })
})

const renderMailboxState: (mailboxState: MailboxState) => void = (
  mailboxState
) => {
  for (const mailbox of mailboxState.mailboxes) {
    console.log(mailbox.name.toString())
    console.log("=".repeat(mailbox.name.value.length))
    for (const email of mailbox.emails) {
      console.log(`- ${email}`)
    }
    console.log()
  }
}

const deleteAllEmails = async (token: string) => {
  const api = await FastmailSession.create(token)
  await api.calls([
    [
      "Mailbox/get",
      {
        accountId: api.accountId,
        ids: null,
      },
      "0",
    ],
    [
      "Email/query",
      {
        accountId: api.accountId,
        filter: {
          operator: "OR",
          conditions: {
            "#inMailboxes": {
              resultOf: "0",
              name: "Mailbox/get",
              path: "list/*/id",
            },
          },
        },
      },
      "1",
    ],
    [
      "Email/set",
      {
        accountId: api.accountId,
        "#destroy": {
          resultOf: "1",
          name: "Email/query",
          path: "/ids",
        },
      },
      "2",
    ],
  ])
}
