import { assertThat, equalTo, falsey, truthy } from "hamjest"
import { ContactsGroupName, MailboxName } from "."

describe(MailboxName.name, () => {
  describe("mapping to contacts group", () => {
    it("Removes the 'Inbox/' prefix", () => {
      const mailbox = MailboxName.of("Inbox/Paperwork")
      assertThat(
        mailbox.contactsGroup,
        equalTo(ContactsGroupName.of("Paperwork"))
      )
    })
  })

  describe("equality", () => {
    it("cannot be found by value in an array using includes", () => {
      const someMailboxes = [MailboxName.of("One"), MailboxName.of("Two")]
      assertThat(someMailboxes.includes(MailboxName.of("One")), falsey())
    })

    it("can be found in array by value manually", () => {
      const someMailboxes = [MailboxName.of("One"), MailboxName.of("Two")]
      assertThat(
        someMailboxes.some((mailbox) => mailbox.equals(MailboxName.of("One"))),
        truthy()
      )
    })
  })
})
