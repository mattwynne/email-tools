import { assertThat, equalTo } from "hamjest"
import { ContactsGroupName } from "."

describe(ContactsGroupName.name, () => {
  describe("equality", () => {
    it("is equal to another instance with the same name", () => {
      assertThat(
        [ContactsGroupName.of("Foo")],
        equalTo([ContactsGroupName.of("Foo")])
      )
    })
  })
})
