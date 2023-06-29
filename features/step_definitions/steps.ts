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

Given(
  "an email in {mailbox} from {email address}",
  function (this: World, mailbox: MailboxName, sender: EmailAddress) {
    console.log("TODO: stub an email from", sender, "in", mailbox)
    this.theEmail = { from: sender }
  }
)

When(
  "Matt drags the email into the {mailbox} folder",
  function (this: World, toMailbox: MailboxName) {
    console.log(
      "TODO: simulate the email moving into the",
      toMailbox,
      "mailbox"
    )
    this.contactsProvider.addToGroup(
      this.theEmail.from,
      toMailbox.contactsGroup
    )
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
  "{email address} should be added to the {contacts group}",
  function (this: World, email, group) {
    assertThat(
      this.contactsChanges[0],
      equalTo({ action: "add", email, group })
    )
  }
)
