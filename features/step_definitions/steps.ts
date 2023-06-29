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

type Email = {
  from: EmailAddress
}

class EmailProvider {
  static createNull() {
    return new this()
  }
}

class Application {
  constructor(
    private readonly emailProvider: EmailProvider,
    private readonly contactsProvider: ContactsProvider
  ) {}

  processNewMailboxState(state: MailboxState) {
    state.mailboxes[0]
    this.contactsProvider.addToGroup(
      state.mailboxes[0].emails[0].from,
      state.mailboxes[0].name.contactsGroup
    )
  }
}

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

class MailboxState {
  constructor(public readonly mailboxes: Mailbox[]) {}
}

class Mailbox {
  constructor(
    public readonly name: MailboxName,
    public readonly emails: Email[]
  ) {}
}

Given(
  "an email in {mailbox} from {email address}",
  function (this: World, mailboxName: MailboxName, sender: EmailAddress) {
    this.theEmail = { from: sender }
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
  function (this: World, email, group) {
    assertThat(this.contactsChanges, equalTo([{ action: "add", email, group }]))
  }
)
