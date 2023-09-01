import { MailboxName, MailboxState } from "../../core"

export interface EmailAccount {
  getMailboxState: (onlyMailboxNames?: MailboxName[]) => Promise<MailboxState>
}

export class NullEmailAccount implements EmailAccount {
  constructor(private readonly mailboxStates: MailboxState[]) {}

  async getMailboxState(onlyMailboxNames?: MailboxName[]) {
    const nextMailboxState = this.mailboxStates.shift()
    if (!nextMailboxState)
      throw new Error("You don't have any more configured MailboxStates")
    if (!onlyMailboxNames) return nextMailboxState
    return new MailboxState(
      nextMailboxState.mailboxes.filter((mailbox) =>
        onlyMailboxNames.some((name) => name.equals(mailbox.name))
      )
    )
  }
}
