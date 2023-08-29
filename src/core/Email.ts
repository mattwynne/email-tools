import { TinyType } from "tiny-types"
import { EmailAddress, EmailSubject } from "."

export class Email extends TinyType {
  static from(sender: string | EmailAddress) {
    return new Email(EmailAddress.of(sender), EmailSubject.unknown())
  }

  private constructor(
    public readonly from: EmailAddress,
    public readonly subject: EmailSubject
  ) {
    super()
  }

  public about(subject: EmailSubject) {
    return new Email(this.from, subject)
  }

  toString() {
    return `${this.subject} [${this.from}]`
  }
}
