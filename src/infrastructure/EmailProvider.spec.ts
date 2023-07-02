import { Email } from "../core/Email"
import { MailboxState } from "../core/MailboxState"
import { Mailbox } from "../core/Mailbox"
import { EmailAddress } from "../core/EmailAddress"
import { MailboxName } from "../core/MailboxName"
import { EmailProvider } from "./EmailProvider"

describe(EmailProvider.name, () => {
  describe("null mode", () => {
    it("can be created with a stubbed MailboxState", () => {
      const mailboxState = new MailboxState([
        new Mailbox(MailboxName.of("Inbox/Paperwork"), [
          Email.from(EmailAddress.of("someone@example.com")),
        ]),
      ])
      const provider = EmailProvider.createNull({ mailboxState })
    })
  })

  describe("fastmail mode", () => {
    it("connects to a real fastmail inbox", () => {})
  })
})
