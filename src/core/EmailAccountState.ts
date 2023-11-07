import { MailboxState, MailboxName } from "."

export class EmailAccountState {
  ofMailboxes(onlyMailboxesNamed: MailboxName[]) {
    return new EmailAccountState(
      this.mailboxes.filter((mailbox) =>
        onlyMailboxesNamed.some((onlyMailboxName) =>
          onlyMailboxName.equals(mailbox.name)
        )
      ),
      this.mailboxState,
      this.emailState
    )
  }

  constructor(
    public readonly mailboxes: MailboxState[],
    public readonly mailboxState: string,
    public readonly emailState: string
  ) {}
}
