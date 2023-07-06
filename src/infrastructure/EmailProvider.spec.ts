import { Email } from "../core/Email"
import { MailboxState } from "../core/MailboxState"
import { Mailbox } from "../core/Mailbox"
import { EmailAddress } from "../core/EmailAddress"
import { MailboxName } from "../core/MailboxName"
import { EmailProvider, FastmailConfig } from "./EmailProvider"
import { assertThat, equalTo } from "hamjest"
import util from "util"

describe(EmailProvider.name, () => {
  describe("null mode", () => {
    it("can be created with a stubbed MailboxState", async () => {
      const mailboxState = new MailboxState([
        new Mailbox(MailboxName.of("Inbox/Paperwork"), [
          Email.from(EmailAddress.of("someone@example.com")),
        ]),
      ])
      const provider = EmailProvider.createNull({ mailboxState })
      const actual = await provider.getMailboxState()
      assertThat(actual, equalTo(mailboxState))
    })
  })

  describe("fastmail mode", () => {
    it("connects to a real fastmail inbox", async () => {
      const fastmailConfig: FastmailConfig = {
        token: process.env.FASTMAIL_API_TOKEN || "", // TODO: make env nullable infrastructure too
      }
      const provider = await EmailProvider.create(fastmailConfig)
      console.log(
        util.inspect((await provider.getMailboxState()).mailboxes[0], {
          depth: 5,
        })
      )
    })
  })
})
