import Mail from "nodemailer/lib/mailer"
import { MailboxName, Email, UniqueIdentifier } from "."

export class Mailbox {
  static named(name: string | MailboxName) {
    return new this(UniqueIdentifier.unknown(), MailboxName.of(name), [])
  }

  private constructor(
    public readonly id: UniqueIdentifier,
    public readonly name: MailboxName,
    public readonly emails: Email[]
  ) {}

  public withId(id: UniqueIdentifier) {
    return new Mailbox(id, this.name, this.emails)
  }

  public withEmails(emails: Email[]) {
    return new Mailbox(this.id, this.name, emails)
  }
}
