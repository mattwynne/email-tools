import {
  assertThat,
  containsString,
  equalTo,
  rejected,
  promiseThat,
  hasProperty,
  matchesPattern,
} from "hamjest"
import { ContactsGroup } from "../core/ContactsGroup"
import { EmailAddress } from "../core/EmailAddress"
import { Contacts, FastmailCredentials } from "./Contacts"
import { ContactsChange } from "./ContactsChange"
import { DAVClient, DAVNamespaceShort } from "tsdav"

describe(Contacts.name, () => {
  describe("in null mode", () => {
    it("throws an error when creating a group fails", async () => {
      const contacts = Contacts.createNull()
      await promiseThat(
        contacts.createGroup(ContactsGroup.named("Fails")),
        rejected(hasProperty("message", equalTo("Failure")))
      )
    })

    it("throws an error when creating a contact fails", async () => {
      const contacts = Contacts.createNull()
      await promiseThat(
        contacts.createContact(EmailAddress.of("fail@example.com")),
        rejected(hasProperty("message", equalTo("Failure")))
      )
    })

    it("emits a change event when a contact is added to a group", () => {
      const provider = Contacts.createNull()
      const from = EmailAddress.of("somebody@example.com")
      const contactsGroup = ContactsGroup.named("Friends")
      const changes = provider.trackChanges()
      provider.addToGroup(from, contactsGroup)
      assertThat(
        changes.data,
        equalTo([
          ContactsChange.of({
            action: "add",
            emailAddress: from,
            group: contactsGroup,
          }),
        ])
      )
    })
  })

  describe("in connected mode", function () {
    this.timeout(process.env.SLOW_TEST_TIMEOUT || 10000)

    let dav: DAVClient

    beforeEach(async () => {
      const config = FastmailCredentials.create()
      dav = new DAVClient({
        authMethod: "Basic",
        serverUrl: `https://carddav.fastmail.com/dav/addressbooks/user/${config.username}/Default`,
        credentials: {
          username: config.username.replace("@", "+Default@"),
          password: config.password,
        },
        defaultAccountType: "carddav",
      })
      await dav.login()
      const books = await dav.fetchAddressBooks()
      const cards = await dav.fetchVCards({ addressBook: books[0] })
      console.log(cards)
      for (const vCard of cards) {
        await dav.deleteVCard({ vCard })
      }
    })

    it("creates a group", async () => {
      const config = FastmailCredentials.create()
      const contacts = await Contacts.create(config)
      contacts.createGroup(ContactsGroup.named("Feed"))
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
      await contacts.createGroup(ContactsGroup.named("Friends"))
      await contacts.createGroup(ContactsGroup.named("Family"))
      await contacts.createContact(EmailAddress.of("test@test.com"))
      const groups = await contacts.groups()
      assertThat(groups.length, equalTo(2))
    })

    it("adds a contact to an existing group")

    it("emits a change event when a contact is added to a group")
  })
})
