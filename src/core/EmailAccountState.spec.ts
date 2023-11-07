import { MailboxState, MailboxName, EmailAccountState } from "."
import { assertThat, equalTo } from "hamjest"

describe(EmailAccountState.name, () => {
  it("creates a copy with a filtered subset of mailboxes", () => {
    const state = new EmailAccountState(
      [
        MailboxState.named("Inbox"),
        MailboxState.named("Archive"),
        MailboxState.named("Trash"),
      ],
      "1",
      "1"
    ).ofMailboxes([MailboxName.of("Inbox"), MailboxName.of("Trash")])
    assertThat(
      state,
      equalTo(
        new EmailAccountState(
          [MailboxState.named("Inbox"), MailboxState.named("Trash")],
          "1",
          "1"
        )
      )
    )
  })
})
