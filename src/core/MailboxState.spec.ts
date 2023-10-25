import Mail from "nodemailer/lib/mailer"
import { Mailbox, MailboxName, MailboxState } from "."
import { assertThat, equalTo } from "hamjest"

describe(MailboxState.name, () => {
  it("creates a copy with a filtered subset of mailboxes", () => {
    const state = new MailboxState([
      Mailbox.named("Inbox"),
      Mailbox.named("Archive"),
      Mailbox.named("Trash"),
    ]).of([MailboxName.of("Inbox"), MailboxName.of("Trash")])
    assertThat(
      state,
      equalTo(
        new MailboxState([Mailbox.named("Inbox"), Mailbox.named("Trash")])
      )
    )
  })
})
