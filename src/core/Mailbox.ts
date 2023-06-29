import { MailboxName } from "./MailboxName"
import { Email } from "./Email"

export class Mailbox {
  constructor(
    public readonly name: MailboxName,
    public readonly emails: Email[]
  ) {}
}
