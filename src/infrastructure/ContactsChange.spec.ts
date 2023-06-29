import { assertThat, equalTo } from "hamjest"
import { ContactsChange } from "./ContactsChange"
import { EmailAddress } from "../core/EmailAddress"
import { ContactsGroup } from "../core/ContactsGroup"

describe(ContactsChange.name, () => {
  describe("equality", () => {
    it("is equal to another instance with the same name", () => {
      assertThat(
        ContactsChange.of({
          action: "add",
          emailAddress: EmailAddress.of("someone@example.com"),
          group: ContactsGroup.named("Friends"),
        }),
        equalTo(
          ContactsChange.of({
            action: "add",
            emailAddress: EmailAddress.of("someone@example.com"),
            group: ContactsGroup.named("Friends"),
          })
        )
      )
    })
  })
})
