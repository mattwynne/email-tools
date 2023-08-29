import { ContactsGroupName, EmailAddress } from "../../Core"

export class ContactsChange {
  public static of({ action, emailAddress, group }: ContactsChange) {
    return new this(action, emailAddress, group)
  }

  private constructor(
    public readonly action:
      | "add-to-group"
      | "remove-from-group"
      | "create-group"
      | "create-contact",
    public readonly emailAddress?: EmailAddress,
    public readonly group?: ContactsGroupName
  ) {}
}
