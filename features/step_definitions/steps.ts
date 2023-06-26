import {
  Given,
  When,
  Then,
  defineParameterType,
  Before,
} from "@cucumber/cucumber"
import EventEmitter from "events"
import { assertThat, equalTo } from "hamjest"
import { OutputTracker } from "../../src/OutputTracker"

class Mailbox {
  static named(name: string) {
    return new this(name)
  }

  private constructor(public readonly name: string) {}
}

class EmailAddress {
  static of(value: string) {
    return new this(value)
  }

  private constructor(public readonly address: string) {}
}

class ContactsGroup {
  static named(value: string) {
    return new this(value)
  }

  private constructor(public readonly name: string) {}
}

type ContactsChange = {
  action: "add" | "remove"
  email: EmailAddress
  group: ContactsGroup
}

type Email = {
  from: EmailAddress
}

const CHANGE_EVENT = "change"

class ContactsProvider {
  private readonly emitter = new EventEmitter()

  static createNull() {
    return new this()
  }


  addToGroup(from: EmailAddress, contactGroup: string) {
  }

  trackChanges(): OutputTracker<ContactsChange> {
    return OutputTracker.create<ContactsChange>(this.emitter, CHANGE_EVENT)
  }
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
  transformer: (name) => Mailbox.named(name),
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

Given("an email in {mailbox} from {email address}", function (mailbox, sender) {
  console.log("TODO: stub an email from", sender, "in", mailbox)
})

When(
  "Matt drags the email into the {mailbox} folder",
  function (this: World, toMailbox) {
    console.log(
      "TODO: simulate the email moving into the",
      toMailbox,
      "mailbox"
    )
    this.contactsProvider.addToGroup(this.theEmail.from, toMailbox.contactsGroup)
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
    assertThat(this.contactsChanges, equalTo({ action: "add", email, group }))
  }
)
