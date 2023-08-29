import { assertThat, equalTo, isEmpty } from "hamjest"
import { Application } from "./Application"
import { ContactsGroup, ContactsGroupName } from "./core/ContactsGroup"
import { Email } from "./core/Email"
import { EmailAddress } from "./core/EmailAddress"
import { EmailSubject } from "./core/EmailSubject"
import { Mailbox } from "./core/Mailbox"
import { MailboxState } from "./core/MailboxState"
import { Contacts } from "./infrastructure/Contacts"
import { ContactsChange } from "./infrastructure/ContactsChange"
import { EmailProvider } from "./infrastructure/EmailProvider"
import { UniqueIdentifier } from "./core/UniqueIdentifier"

describe(Application.name, () => {
  describe("processing new mailbox state", () => {
    context("with no initial state", () => {
      it("doesn't change any contacts", () => {
        const contactsProvider = Contacts.createNull()
        const changes = contactsProvider.trackChanges()
        const app = new Application(
          EmailProvider.createNull(),
          contactsProvider
        )
        app.processNewMailboxState()
        assertThat(changes.data, isEmpty())
      })
    })

    context("with an email in Inbox/Screener", () => {
      it("adds the contact to an existing Paperwork group when the email is moved to the Inbox/Paperwork mailbox", async () => {
        const contactsProvider = Contacts.createNull({
          groups: [
            ContactsGroup.named("Paperwork").withId(UniqueIdentifier.create()),
          ],
          contacts: [],
        })
        const changes = contactsProvider.trackChanges()
        const theEmail: Email = Email.from("sender@example.com")
        const inScreener = new MailboxState([
          Mailbox.named("Inbox/Screener").withEmails([theEmail]),
        ])
        const movedToPaperwork = new MailboxState([
          Mailbox.named("Inbox/Paperwork").withEmails([theEmail]),
        ])
        const app = new Application(
          EmailProvider.createNull({
            mailboxStates: [inScreener, movedToPaperwork],
          }),
          contactsProvider
        )
        await app.processNewMailboxState()
        await app.processNewMailboxState()
        assertThat(
          changes.data,
          equalTo([
            ContactsChange.of({
              action: "add",
              emailAddress: theEmail.from,
              group: ContactsGroupName.of("Paperwork"),
            }),
          ])
        )
      })
    })
  })
})
