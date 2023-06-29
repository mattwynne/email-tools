import { ContactsGroup } from "./ContactsGroup"
import { assertThat, equalTo } from "hamjest"

describe(ContactsGroup.name, () => {
  describe("equality", () => {
    it("is equal to another instance with the same name", () => {
      assertThat(
        [ContactsGroup.named("Foo")],
        equalTo([ContactsGroup.named("Foo")])
      )
    })
  })
})
