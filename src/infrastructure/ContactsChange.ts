import { ContactsGroupName } from "../core/ContactsGroup"
import { EmailAddress } from "../core/EmailAddress"

export class ContactsChange {
  public static of({ action, emailAddress, group }: ContactsChange) {
    return new this(action, emailAddress, group)
  }

  private constructor(
    public readonly action: "add" | "remove",
    public readonly emailAddress: EmailAddress,
    public readonly group: ContactsGroupName
  ) {}
}
