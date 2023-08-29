import { TinyType } from "tiny-types"
import { EmailAddress, UniqueIdentifier } from "."

export class Contact extends TinyType {
  static withEmail(email: EmailAddress | string) {
    return new this(EmailAddress.of(email), UniqueIdentifier.unknown())
  }

  private constructor(
    public readonly email: EmailAddress,
    public readonly id: UniqueIdentifier
  ) {
    super()
  }

  public withId(id: UniqueIdentifier | string) {
    return new Contact(this.email, UniqueIdentifier.of(id))
  }

  public withEmail(email: EmailAddress) {
    return new Contact(email, this.id)
  }
}
