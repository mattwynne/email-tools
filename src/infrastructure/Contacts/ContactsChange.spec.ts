import { assertThat, equalTo } from "hamjest"
import { ContactsChange } from "./ContactsChange"
import { EmailAddress } from "../../core/EmailAddress"
import { ContactsGroupName } from "../../core/ContactsGroup"

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
