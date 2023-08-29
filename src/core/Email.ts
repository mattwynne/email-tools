import { TinyType } from "tiny-types"
import { EmailAddress } from "./EmailAddress"
import { EmailSubject } from "./EmailSubject"

export class Email extends TinyType {
  static from(sender: EmailAddress) {
    return new Email(sender, EmailSubject.unknown())
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
