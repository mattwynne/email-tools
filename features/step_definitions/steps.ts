import {
  Given,
  When,
  Then,
  defineParameterType,
  Before,
} from "@cucumber/cucumber"
import { assertThat, containsInAnyOrder, equalTo } from "hamjest"
import { MailboxName } from "../../src/core/MailboxName"
import { ContactsGroup } from "../../src/core/ContactsGroup"
import { ContactsProvider } from "../../src/infrastructure/ContactsProvider"
import { EmailAddress } from "../../src/core/EmailAddress"
import { ContactsChange } from "../../src/infrastructure/ContactsChange"
import { Application } from "../../src/Application"
import { MailboxState } from "../../src/core/MailboxState"
import { Mailbox } from "../../src/core/Mailbox"
import { Email } from "../../src/core/Email"
import { EmailProvider } from "../../src/infrastructure/EmailProvider"
import { EmailSubject } from "../../src/core/EmailSubject"

defineParameterType({
  name: "mailbox",
  regexp: /(Inbox\/\w+)/,
  transformer: (name) => MailboxName.of(name),
})

defineParameterType({
  name: "email address",
  regexp: /(\w+@\w+\.\w+)/,
  transformer: (address) => EmailAddress.of(address),
})

defineParameterType({
  name: "contacts group",
  regexp: /(\w+) contacts group/,
  transformer: (name) => ContactsGroup.named(name),
})

Given(
  "an email in {mailbox} from {email address}",
  function (this: World, mailboxName: MailboxName, sender: EmailAddress) {
    this.theEmail = Email.from(sender)
    const mailbox = Mailbox.named(mailboxName).withEmails([this.theEmail])
    const mailboxState: MailboxState = new MailboxState([mailbox])
    this.mailboxStates.push(mailboxState)
  }
)

When(
  "the email is added to {mailbox}",
  async function (this: World, toMailbox: MailboxName) {
    const mailbox = Mailbox.named(toMailbox).withEmails([this.theEmail])
    const mailboxState: MailboxState = new MailboxState([mailbox])
    this.mailboxStates.push(mailboxState)

    const app = this.app()
    await app.processNewMailboxState()
    await app.processNewMailboxState()
  }
)

type World = {
  contactsProvider: ContactsProvider
  contactsChanges: ContactsChange[]
  app: () => Application
  theEmail: Email
  mailboxStates: MailboxState[]
}

Before(function (this: World) {
  this.contactsProvider = ContactsProvider.createNull()
  this.contactsChanges = this.contactsProvider.trackChanges().data
  const emailProvider = () => EmailProvider.createNull(this)
  this.app = () => {
    return new Application(emailProvider(), this.contactsProvider)
  }
  this.mailboxStates = []
})

Then(
  "{email address} should only have been added to the {contacts group}",
  function (this: World, emailAddress, group) {
    assertThat(
      this.contactsChanges,
      equalTo([ContactsChange.of({ action: "add", emailAddress, group })])
    )
  }
)
