import { TinyType, TinyTypeOf } from "tiny-types"
import { UniqueIdentifier } from "."

export class ContactsGroupName extends TinyTypeOf<string>() {
  static of(value: string | ContactsGroupName) {
    if (typeof value !== "string") return value
    return new this(value)
  }
}

export class ContactsGroup extends TinyType {
  static named(name: string | ContactsGroupName) {
    return new this(ContactsGroupName.of(name), UniqueIdentifier.unknown())
  }

  private constructor(
    public readonly name: ContactsGroupName,
    public readonly id: UniqueIdentifier
  ) {
    super()
  }

  public withId(id: string | UniqueIdentifier) {
    return new ContactsGroup(this.name, UniqueIdentifier.of(id))
  }

  public withName(name: ContactsGroupName) {
    return new ContactsGroup(name, this.id)
  }
}
