import { Mailbox } from "./Mailbox"

export class MailboxState {
  constructor(public readonly mailboxes: Mailbox[]) {}
}
