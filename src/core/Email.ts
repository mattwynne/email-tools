import { TinyType } from "tiny-types"
import { EmailAddress, EmailSubject, UniqueIdentifier } from "."

export class Email extends TinyType {
  static withId(id: UniqueIdentifier) {
    return new Email(id, EmailAddress.unknown(), EmailSubject.unknown())
  }

  static from(sender: string | EmailAddress) {
    return new Email(
      UniqueIdentifier.unknown(),
      EmailAddress.of(sender),
      EmailSubject.unknown()
    )
  }

  private constructor(
    public readonly id: UniqueIdentifier,
    public readonly from: EmailAddress,
    public readonly subject: EmailSubject
  ) {
    super()
  }

  public about(subject: EmailSubject) {
    return new Email(this.id, this.from, subject)
  }

  toString() {
    return `${this.subject} [${this.from}]`
  }
}
