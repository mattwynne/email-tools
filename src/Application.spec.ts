import { assertThat, equalTo, isEmpty } from "hamjest"
import { Application } from "./Application"
import {
  ContactsGroup,
  ContactsGroupName,
  Email,
  MailboxState,
  EmailAccountState,
  UniqueIdentifier,
} from "./core"
import { Contacts, ContactsChange } from "./infrastructure/contacts"
import { FastmailAccount } from "./infrastructure/emails"

describe.skip(Application.name, () => {
  describe("processing new mailbox state", () => {
    context("with no initial state", () => {
      it("doesn't change any contacts", () => {
        const contactsProvider = Contacts.createNull()
        const changes = contactsProvider.trackChanges()
        const app = new Application(
          FastmailAccount.createNull(),
          contactsProvider
        )
        app.processNewEmailAccountState()
        assertThat(changes.data, isEmpty())
      })
    })

    context("with an email in Inbox/Screener", () => {
      it("@wip adds the contact to an existing Paperwork group when the email is moved to the Inbox/Paperwork mailbox", async () => {
        // const contactsProvider = Contacts.createNull({
        //   groups: [
        //     ContactsGroup.named("Paperwork").withId(UniqueIdentifier.create()),
        //   ],
        //   contacts: [],
        // })
        // const changes = contactsProvider.trackChanges()
        // const theEmail: Email = Email.from("sender@example.com")
        // const inScreener = new EmailAccountState([
        //   MailboxState.named("Inbox/Screener").withEmailIds([theEmail]),
        // ])
        // const movedToPaperwork = new EmailAccountState([
        //   MailboxState.named("Inbox/Paperwork").withEmailIds([theEmail]),
        // ])
        // const app = new Application(
        //   FastmailAccount.createNull({
        //     EmailAccountStates: [inScreener, movedToPaperwork],
        //   }),
        //   contactsProvider
        // )
        // await app.processNewEmailAccountState()
        // await app.processNewEmailAccountState()
        // assertThat(
        //   changes.data,
        //   equalTo([
        //     ContactsChange.of({
        //       action: "add-to-group",
        //       emailAddress: theEmail.from,
        //       group: ContactsGroupName.of("Paperwork"),
        //     }),
        //   ])
        // )
      })
    })
  })
})
