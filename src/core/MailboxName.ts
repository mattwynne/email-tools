import { TinyTypeOf } from "tiny-types"
import { ContactsGroupName } from "."

export class MailboxName extends TinyTypeOf<string>() {
  static of(name: string | MailboxName) {
    if (typeof name !== "string") return name
    return new this(name)
  }

  public get contactsGroup(): ContactsGroupName {
    return ContactsGroupName.of(this.value.replace(/^Inbox\//, ""))
  }

  public toString() {
    return this.value
  }
}
