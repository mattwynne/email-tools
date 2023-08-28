import { assertThat, equalTo, isEmpty } from "hamjest"
import { MailboxState } from "./core/MailboxState"
import { Application } from "./Application"
import { Contacts } from "./infrastructure/Contacts"
import { Mailbox } from "./core/Mailbox"
import { MailboxName } from "./core/MailboxName"
import { Email } from "./core/Email"
import { ContactsChange } from "./infrastructure/ContactsChange"
import { ContactsGroup } from "./core/ContactsGroup"
import assert from "assert"
import { EmailProvider } from "./infrastructure/EmailProvider"
import { EmailAddress } from "./core/EmailAddress"
import { EmailSubject } from "./core/EmailSubject"

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
      it("adds the contact to Paperwork when the email is moved to the Inbox/Paperwork mailbox", async () => {
        const contactsProvider = Contacts.createNull()
        const changes = contactsProvider.trackChanges()
        const theEmail: Email = Email.from(
          EmailAddress.of("sender@example.com")
        ).about(EmailSubject.of("A subject"))
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
              group: ContactsGroup.named("Paperwork"),
            }),
          ])
        )
      })
    })
  })
})
