import { MailboxName } from "./MailboxName"
import { Email } from "./Email"

export class Mailbox {
  static named(name: string | MailboxName) {
    return new this(MailboxName.of(name), [])
  }

  private constructor(
    public readonly name: MailboxName,
    public readonly emails: Email[]
  ) {}

  public withEmails(emails: Email[]) {
    return new Mailbox(this.name, emails)
  }
}
