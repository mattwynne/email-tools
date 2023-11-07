import { MailboxName, EmailAccountState } from "../../core"

export class NullEmailAccount {
  constructor(private readonly EmailAccountStates: EmailAccountState[]) {}

  async getEmailAccountState(onlyMailboxNames?: MailboxName[]) {
    const nextEmailAccountState = this.EmailAccountStates.shift()
    if (!nextEmailAccountState)
      throw new Error("You don't have any more configured EmailAccountStates")
    if (!onlyMailboxNames) return nextEmailAccountState
    return new EmailAccountState(
      nextEmailAccountState.mailboxes.filter((mailbox) =>
        onlyMailboxNames.some((name) => name.equals(mailbox.name))
      ),
      "1",
      "1"
    )
  }

  onChange(handler: () => void) {}
  close() {}
}
