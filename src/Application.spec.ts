import { assertThat, equalTo, isEmpty } from "hamjest"
import { MailboxState } from "./core/MailboxState"
import { Application } from "./Application"
import { ContactsProvider } from "./infrastructure/ContactsProvider"
import { Mailbox } from "./core/Mailbox"
import { MailboxName } from "./core/MailboxName"
import { Email } from "./core/Email"
import { ContactsChange } from "./infrastructure/ContactsChange"
import { ContactsGroup } from "./core/ContactsGroup"
import assert from "assert"
import { EmailProvider } from "./infrastructure/EmailProvider"

describe(Application.name, () => {
  describe("processing new mailbox state", () => {
    context("with no initial state", () => {
      it("doesn't change any contacts", () => {
        const contactsProvider = ContactsProvider.createNull()
        const changes = contactsProvider.trackChanges()
        const app = new Application(
          EmailProvider.createNull(),
          contactsProvider
        )
        app.processNewMailboxState(new MailboxState([]))
        assertThat(changes.data, isEmpty())
      })
    })

    context("with an email in Inbox/Screener", () => {
      it("adds the contact to Paperwork when the email is moved to the Inbox/Paperwork mailbox", () => {
        const contactsProvider = ContactsProvider.createNull()
        const changes = contactsProvider.trackChanges()
        const app = new Application(
          EmailProvider.createNull(),
          contactsProvider
        )
        const theEmail: Email = { from: { address: "sender@example.com" } }
        const initialState = new MailboxState([
          new Mailbox(MailboxName.of("Inbox/Screener"), [theEmail]),
        ])
        app.processNewMailboxState(initialState)
        const newState = new MailboxState([
          new Mailbox(MailboxName.of("Inbox/Paperwork"), [theEmail]),
        ])
        app.processNewMailboxState(newState)
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
