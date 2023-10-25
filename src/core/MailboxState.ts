import { Mailbox, MailboxName } from "."

export class MailboxState {
  of(onlyMailboxesNamed: MailboxName[]) {
    return new MailboxState(
      this.mailboxes.filter((mailbox) =>
        onlyMailboxesNamed.some((onlyMailboxName) =>
          onlyMailboxName.equals(mailbox.name)
        )
      )
    )
  }

  constructor(public readonly mailboxes: Mailbox[]) {}
}
