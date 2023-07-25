import { ContactsGroup } from "./ContactsGroup"
import { TinyTypeOf } from "tiny-types"

export class MailboxName extends TinyTypeOf<string>() {
  static of(name: string | MailboxName) {
    if (typeof name !== "string") return name
    return new this(name)
  }

  public get contactsGroup(): ContactsGroup {
    return ContactsGroup.named(this.value.replace(/^Inbox\//, ""))
  }

  public toString() {
    return this.value
  }
}
