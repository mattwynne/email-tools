import { Email } from "../core/Email"
import { MailboxState } from "../core/MailboxState"
import { Mailbox } from "../core/Mailbox"
import { EmailAddress } from "../core/EmailAddress"
import { MailboxName } from "../core/MailboxName"
import { EmailProvider, FastmailConfig } from "./EmailProvider"
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
      this.timeout(5000)
      const fastmailConfig: FastmailConfig = {
        token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
      }
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
