import { assertThat, equalTo } from "hamjest"
import { Mailbox } from "./Mailbox"
import { ContactsGroup } from "./ContactsGroup"

describe(Mailbox.name, () => {
  describe("mapping to contacts group", () => {
    it("Removes the 'Inbox/' prefix", () => {
      const mailbox = Mailbox.named("Inbox/Paperwork")
      assertThat(
        mailbox.contactsGroup,
        equalTo(ContactsGroup.named("Paperwork"))
      )
    })
  })
})
