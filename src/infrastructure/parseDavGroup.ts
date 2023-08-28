import { ContactsGroup } from "../core/ContactsGroup"

export function parseDavGroup(data: string): ContactsGroup {
  const matches = data.matchAll(/(.*):(.*)/g)
  if (!matches) throw new Error("Data has no fields!")
  const fields = new Map()
  for (const match of matches) {
    fields.set(match[1], match[2])
  }
  return ContactsGroup.named(fields.get("N"))
}
