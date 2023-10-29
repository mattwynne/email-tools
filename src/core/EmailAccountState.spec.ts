import { Mailbox, MailboxName, EmailAccountState } from "."
import { assertThat, equalTo } from "hamjest"

describe(EmailAccountState.name, () => {
  it("creates a copy with a filtered subset of mailboxes", () => {
    const state = new EmailAccountState([
      Mailbox.named("Inbox"),
      Mailbox.named("Archive"),
      Mailbox.named("Trash"),
    ]).ofMailboxes([MailboxName.of("Inbox"), MailboxName.of("Trash")])
    assertThat(
      state,
      equalTo(
        new EmailAccountState([Mailbox.named("Inbox"), Mailbox.named("Trash")])
      )
    )
  })
})
