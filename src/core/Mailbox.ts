import { MailboxName } from "./MailboxName"
import { Email } from "./Email"

export class Mailbox {
  static named(name: string) {
    return new this(MailboxName.of(name), [])
  }

  constructor(
    public readonly name: MailboxName,
    public readonly emails: Email[]
  ) {}
}
