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
    this.theEmail = Email.from(sender).about(EmailSubject.of("a subject"))
    const mailbox = new Mailbox(mailboxName, [this.theEmail])
    const mailboxState: MailboxState = new MailboxState([mailbox])
    this.app.processNewMailboxState(mailboxState)
  }
)

When(
  "the email is added to {mailbox}",
  function (this: World, toMailbox: MailboxName) {
    const mailbox = new Mailbox(toMailbox, [this.theEmail])
    const mailboxState: MailboxState = new MailboxState([mailbox])
    this.app.processNewMailboxState(mailboxState)
  }
)

type World = {
  contactsProvider: ContactsProvider
  contactsChanges: ContactsChange[]
  app: Application
  theEmail: Email
}

Before(function (this: World) {
  const emailProvider = EmailProvider.createNull()
  this.contactsProvider = ContactsProvider.createNull()
  this.app = new Application(emailProvider, this.contactsProvider)
  this.contactsChanges = this.contactsProvider.trackChanges().data
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
