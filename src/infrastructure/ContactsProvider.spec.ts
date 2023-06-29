import { assertThat, equalTo } from "hamjest"
import { ContactsGroup } from "../core/ContactsGroup"
import { EmailAddress } from "../core/EmailAddress"
import { ContactsProvider } from "./ContactsProvider"
import { ContactsChange } from "./ContactsChange"

describe(ContactsProvider.name, () => {
  describe("in null mode", () => {
    it("emits a change event when a contact is added to a group", () => {
      const provider = ContactsProvider.createNull()
      const from = EmailAddress.of("somebody@example.com")
      const contactsGroup = ContactsGroup.named("Friends")
      const changes = provider.trackChanges()
      provider.addToGroup(from, contactsGroup)
      assertThat(
        changes.data,
        equalTo([
          ContactsChange.of({
            action: "add",
            emailAddress: from,
            group: contactsGroup,
          }),
        ])
      )
    })
  })

  describe("in connected mode", () => {
    it("adds a contact to a group")
    it("emmits a change event when a contact is added to a group")
  })
})
