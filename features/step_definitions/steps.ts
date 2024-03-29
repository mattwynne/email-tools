import {
  Before,
  Given,
  Then,
  When,
  defineParameterType,
} from "@cucumber/cucumber"
import { assertThat, equalTo } from "hamjest"
import { Application } from "../../src/Application"
import {
  ContactsGroupName,
  Email,
  EmailAddress,
  MailboxState,
  MailboxName,
  EmailAccountState,
} from "../../src/core"
import { Contacts, ContactsChange } from "../../src/infrastructure/contacts"
import { FastmailAccount } from "../../src/infrastructure/emails"

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
  transformer: (name) => ContactsGroupName.of(name),
})

Given(
  "an email in {mailbox} from {email address}",
  function (this: World, mailboxName: MailboxName, sender: EmailAddress) {
    // this.theEmail = Email.from(sender)
    // const mailbox = MailboxState.named(mailboxName).withEmailIds([
    //   this.theEmail,
    // ])
    // const emailAccountState = new EmailAccountState([mailbox])
    // this.emailAccountStates.push(emailAccountState)
  }
)

When(
  "the email is added to {mailbox}",
  async function (this: World, toMailbox: MailboxName) {
    // const mailbox = MailboxState.named(toMailbox).withEmailIds([this.theEmail])
    // const emailAccountState = new EmailAccountState([mailbox])
    // this.emailAccountStates.push(emailAccountState)
    // const app = this.app()
    // await app.processNewEmailAccountState()
    // await app.processNewEmailAccountState()
  }
)

type World = {
  contactsProvider: Contacts
  contactsChanges: ContactsChange[]
  app: () => Application
  theEmail: Email
  emailAccountStates: EmailAccountState[]
}

Before(function (this: World) {
  this.contactsProvider = Contacts.createNull()
  this.contactsChanges = this.contactsProvider.trackChanges().data
  const fastmailAccount = () => FastmailAccount.createNull(this)
  this.app = () => {
    return new Application(fastmailAccount(), this.contactsProvider)
  }
  this.emailAccountStates = []
})

Then(
  "{email address} should only have been added to the {contacts group}",
  function (this: World, emailAddress, group) {
    assertThat(
      this.contactsChanges,
      equalTo([
        ContactsChange.of({ action: "add-to-group", emailAddress, group }),
      ])
    )
  }
)
