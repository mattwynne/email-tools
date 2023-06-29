import { ContactsGroup } from "./ContactsGroup"

export class MailboxName {
  static of(name: string) {
    return new this(name)
  }

  private constructor(public readonly name: string) {}

  public get contactsGroup(): ContactsGroup {
    return ContactsGroup.named(this.name.replace(/^Inbox\//, ""))
  }
}