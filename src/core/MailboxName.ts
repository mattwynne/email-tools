import { inherits } from "util"
import { ContactsGroup } from "./ContactsGroup"

export class MailboxName extends String {
  static of(name: string) {
    return new this(name)
  }

  private constructor(private readonly name: string) {
    super(name)
  }

  public get contactsGroup(): ContactsGroup {
    return ContactsGroup.named(this.name.replace(/^Inbox\//, ""))
  }
}
