import { Contact } from "../../core/Contact"
import { ContactsGroup } from "../../core/ContactsGroup"
import { EmailAddress } from "../../core/EmailAddress"
import { UniqueIdentifier } from "../../core/UniqueIdentifier"

export function parseDavGroup(data: string): ContactsGroup {
  const fields = parseFields(data)
  return ContactsGroup.named(fields.get("N")).withId(fields.get("UID"))
}

export function parseDavContact(data: string): Contact {
  const fields = parseFields(data)
  return Contact.withEmail(EmailAddress.of(fields.get("EMAIL"))).withId(
    new UniqueIdentifier(fields.get("UID"))
  )
}

function parseFields(data: string) {
  const matches = data.matchAll(/(\w+)(?:;.+)?:(.*)/g)
  if (!matches) throw new Error("Data has no fields!")
  const fields = new Map()
  for (const match of matches) {
    fields.set(match[1], match[2])
  }
  return fields
}
