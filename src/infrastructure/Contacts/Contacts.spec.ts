import {
  assertThat,
  containsInAnyOrder,
  containsString,
  equalTo,
  hasProperty,
  matchesPattern,
  promiseThat,
  rejected,
} from "hamjest"
import { DAVClient } from "tsdav"
import { Contact } from "../../core/Contact"
import { ContactsGroup, ContactsGroupName } from "../../core/ContactsGroup"
import { EmailAddress } from "../../core/EmailAddress"
import { Contacts } from "./Contacts"
import { Fastmail, FastmailCredentials } from "./Fastmail"
import { ContactsChange } from "./ContactsChange"

describe(Contacts.name, () => {
  describe("in null mode", () => {
    describe("creating groups", () => {
      it("throws an error when creating a group fails", async () => {
        const contacts = Contacts.createNull()
        await promiseThat(
          contacts.createGroupNamed(ContactsGroupName.of("Fails")),
          rejected(hasProperty("message", equalTo("Failure")))
        )
      })

      it("emits an event", async () => {
        const contacts = Contacts.createNull()
        const changes = contacts.trackChanges()
        const group = ContactsGroupName.of("Friends")
        await contacts.createGroupNamed(group)
        assertThat(
          changes.data,
          equalTo([
            ContactsChange.of({
              action: "create-group",
              group,
            }),
          ])
        )
      })
    })

    describe("creating contacts", () => {
      it("throws an error when creating a contact fails", async () => {
        const contacts = Contacts.createNull()
        await promiseThat(
          contacts.createContact(EmailAddress.of("fail@example.com")),
          rejected(hasProperty("message", equalTo("Failure")))
        )
      })

      it("emits an event", async () => {
        const contacts = Contacts.createNull()
        const changes = contacts.trackChanges()
        const emailAddress = EmailAddress.of("test@example.com")
        await contacts.createContact(emailAddress)
        assertThat(
          changes.data,
          equalTo([
            ContactsChange.of({
              action: "create-contact",
              emailAddress,
            }),
          ])
        )
      })
    })

    describe("adding a contact to a group", () => {
      it("emits a change event when a contact is added to a group", async () => {
        const from = EmailAddress.of("somebody@example.com")
        const group = ContactsGroupName.of("Friends")
        const provider = Contacts.createNull({
          groups: [ContactsGroup.named(group).withId("1")],
          contacts: [Contact.withEmail(from).withId("2")],
        })
        const changes = provider.trackChanges()
        await provider.addToGroup(from, group)
        assertThat(
          changes.data,
          equalTo([
            ContactsChange.of({
              action: "add-to-group",
              emailAddress: from,
              group,
            }),
          ])
        )
      })
    })

    it("returns stubbed groups", async () => {
      const provider = Contacts.createNull({
        groups: [
          ContactsGroup.named("Friends").withId("1"),
          ContactsGroup.named("Family").withId("2"),
        ],
        contacts: [],
      })
      const groups = await provider.groups()
      assertThat(
        groups.map((group) => group.name.value),
        containsInAnyOrder("Friends", "Family")
      )
    })

    it("returns stubbed contacts", async () => {
      const provider = Contacts.createNull({
        groups: [],
        contacts: [Contact.withEmail("test@test.com").withId("1")],
      })
      const actual = await provider.contacts()
      assertThat(
        actual.map((contact) => contact.email.value),
        containsInAnyOrder("test@test.com")
      )
    })
  })

  describe("in connected mode @online", function () {
    this.timeout(process.env.SLOW_TEST_TIMEOUT || 10000)

    let dav: DAVClient

    beforeEach(async () => {
      const config = FastmailCredentials.create()
      dav = await Fastmail.createDavClient(config)
      const books = await dav.fetchAddressBooks()
      const cards = await dav.fetchVCards({ addressBook: books[0] })
      for (const vCard of cards) {
        await dav.deleteVCard({ vCard })
      }
    })

    it("creates a group", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      contacts.createGroupNamed(ContactsGroupName.of("Feed"))
      const books = await dav.fetchAddressBooks()
      const cards = await dav.fetchVCards({ addressBook: books[0] })
      assertThat(cards.length, equalTo(1))
      assertThat(cards[0].data, containsString("N:Feed"))
      assertThat(cards[0].data, containsString("FN:Feed"))
      assertThat(
        cards[0].data,
        containsString("X-ADDRESSBOOKSERVER-KIND:group")
      )
    })

    it("creates a contact", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      await contacts.createContact(EmailAddress.of("test@example.com"))
      const books = await dav.fetchAddressBooks()
      const cards = await dav.fetchVCards({ addressBook: books[0] })
      assertThat(cards.length, equalTo(1))
      const data = cards[0].data
      assertThat(data, matchesPattern("EMAIL.*:test@example.com"))
    })

    it("lists groups", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      await contacts.createGroupNamed(ContactsGroupName.of("Friends"))
      await contacts.createGroupNamed(ContactsGroupName.of("Family"))
      await contacts.createContact(EmailAddress.of("test@test.com"))
      const groups = await contacts.groups()
      assertThat(groups.length, equalTo(2))
      assertThat(
        groups.map((group) => group.name.value),
        containsInAnyOrder("Friends", "Family")
      )
    })

    it("lists contacts", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      await contacts.createGroupNamed(ContactsGroupName.of("Friends"))
      await contacts.createContact(EmailAddress.of("test@test.com"))
      await contacts.createContact(EmailAddress.of("someone@test.com"))
      const people = await contacts.contacts()
      assertThat(people.length, equalTo(2))
      assertThat(
        people.map((person) => person.email.value),
        containsInAnyOrder("test@test.com", "someone@test.com")
      )
    })

    it("adds a contact to an existing group", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      const group = ContactsGroupName.of("Friends")
      const email = EmailAddress.of("test@test.com")
      await contacts.createGroupNamed(group)
      await contacts.createContact(email)
      await contacts.addToGroup(email, group)
      const books = await dav.fetchAddressBooks()
      const cards = await dav.fetchVCards({ addressBook: books[0] })
      assertThat(cards.length, equalTo(2))
      const groups = cards.filter((card) =>
        card.data?.match(/X-ADDRESSBOOKSERVER-KIND:group\r\n/)
      )
      assertThat(groups.length, equalTo(1))
      assertThat(
        groups[0].data,
        matchesPattern(/X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:/)
      )
    })

    it("emits a change event when a contact is added to a group")
  })
})
