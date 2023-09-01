import { assertThat, equalTo } from "hamjest"
import { ContactsGroupName, EmailAddress } from "../../core"
import { ContactsChange } from "./ContactsChange"

describe(ContactsChange.name, () => {
  describe("equality", () => {
    it("is equal to another instance with the same name", () => {
      assertThat(
        ContactsChange.of({
          action: "add-to-group",
          emailAddress: EmailAddress.of("someone@example.com"),
          group: ContactsGroupName.of("Friends"),
        }),
        equalTo(
          ContactsChange.of({
            action: "add-to-group",
            emailAddress: EmailAddress.of("someone@example.com"),
            group: ContactsGroupName.of("Friends"),
          })
        )
      )
    })
  })
})
