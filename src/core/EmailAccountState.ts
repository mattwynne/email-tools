import { Mailbox, MailboxName } from "."

export class EmailAccountState {
  ofMailboxes(onlyMailboxesNamed: MailboxName[]) {
    return new EmailAccountState(
      this.mailboxes.filter((mailbox) =>
        onlyMailboxesNamed.some((onlyMailboxName) =>
          onlyMailboxName.equals(mailbox.name)
        )
      )
    )
  }

  constructor(public readonly mailboxes: Mailbox[]) {}
}
