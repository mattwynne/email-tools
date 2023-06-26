import { assertThat, equalTo } from "hamjest"
import { MailboxName } from "./MailboxName"
import { ContactsGroup } from "./ContactsGroup"

describe(MailboxName.name, () => {
  describe("mapping to contacts group", () => {
    it("Removes the 'Inbox/' prefix", () => {
      const mailbox = MailboxName.of("Inbox/Paperwork")
      assertThat(
        mailbox.contactsGroup,
        equalTo(ContactsGroup.named("Paperwork"))
      )
    })
  })
})
