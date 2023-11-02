import { assertThat, equalTo, is, truthy } from "hamjest"
import { eventually } from "ts-eventually"
import { Email, EmailAddress, EmailSubject, MailboxName } from "../../core"
import { FastmailAccount } from "./FastmailAccount"
import { FastmailConfig } from "./FastmailSession"
import { reset } from "./reset"
import { sendTestEmail } from "./sendTestEmail"

describe(FastmailAccount.name, () => {
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
      await FastmailAccount.connect(config, async (account) => {
        await sendTestEmail(
          Email.from("someone@example.com").about(EmailSubject.of("a subject"))
        )
        await eventually(async () => {
          const mailboxState = account.state.ofMailboxes([
            MailboxName.of("Inbox"),
          ])
          assertThat(mailboxState.mailboxes.length, equalTo(1))
          assertThat(mailboxState.mailboxes[0].emailIds.length, equalTo(1))
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
        await eventually(async () => assertThat(eventReceived, is(truthy())))
      })
    })
  })
})
