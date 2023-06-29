import { ContactsGroup } from "../core/ContactsGroup"
import { EmailAddress } from "../core/EmailAddress"

export type ContactsChange = {
  action: "add" | "remove"
  email: EmailAddress
  group: ContactsGroup
}
