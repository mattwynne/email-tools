import { TinyType } from "tiny-types"
import { EmailAddress } from "./EmailAddress"
import { EmailSubject } from "./EmailSubject"

export class Email extends TinyType {
  static from(sender: EmailAddress) {
    return {
      about: (subject: EmailSubject) => new Email(sender, subject),
    }
  }

  private constructor(
    public readonly from: EmailAddress,
    public readonly subject: EmailSubject
  ) {
    super()
  }

  toString() {
    return `${this.subject} [${this.from}]`
  }
}
