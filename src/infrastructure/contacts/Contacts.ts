import EventEmitter from "events"
import { DAVVCard } from "tsdav"
import {
  Contact,
  ContactsGroup,
  ContactsGroupName,
  EmailAddress,
} from "../../core"
import { OutputTracker } from "../OutputTracker"
import { ContactsChange } from "./ContactsChange"
import { Credentials, Fastmail } from "./Fastmail"
import { parseDavContact, parseDavGroup } from "./parseDav"

export const CHANGE_EVENT = "change"

type DavAddressBook = { url: string }

type DavClient = {
  createVCard: (params: {
    addressBook: DavAddressBook
    filename: string
    vCardString: string
  }) => Promise<DavResponse>

  updateVCard: (params: {
    vCard: {
      url: string
      data: string
      etag: string
    }
  }) => Promise<DavResponse>

  fetchVCards: (params: { addressBook: DavAddressBook }) => Promise<DavObject[]>
}

type DavResponse = {
  ok: boolean
  statusText: string
}

type DavObject = { data?: string }

class NullDavClient implements DavClient {
  constructor(public readonly config: { cards: DAVVCard[] }) {}

  public async createVCard({ vCardString }: { vCardString: string }) {
    if (vCardString.match(/fail/i)) {
      return Promise.resolve({ ok: false, statusText: "Failure" })
    }
    return Promise.resolve({ ok: true, statusText: "OK" })
  }

  public async updateVCard() {
    return Promise.resolve({ ok: true, statusText: "OK" })
  }

  public async fetchVCards() {
    return Promise.resolve(this.config.cards)
  }
}

class NullDavAddressBook implements DavAddressBook {
  public url: string = "https://whatever.com"
}

export class Contacts {
  private readonly emitter = new EventEmitter()

  static createNull(
    config: { groups: ContactsGroup[]; contacts: Contact[] } = {
      groups: [],
      contacts: [],
    }
  ) {
    const addressBook = new NullDavAddressBook()
    const cards = config.groups
      .map((group) => ({
        addressBook,
        data:
          "BEGIN:VCARD\r\n" +
          "VERSION:3.0\r\n" +
          `UID:${group.id.value}\r\n` +
          `N:${group.name.value}\r\n` +
          `FN:${group.name.value}\r\n` +
          "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
          `REV:${new Date()}\r\n` +
          "END:VCARD",
        filename: `${group.id.value}.vcf`,
        etag: "an-etag",
        url: "a-url",
      }))
      .concat(
        config.contacts.map((contact) => ({
          addressBook,
          data:
            "BEGIN:VCARD\r\n" +
            "VERSION:3.0\r\n" +
            `UID:${contact.id.value}\r\n` +
            `EMAIL:${contact.email.value}\r\n` +
            `N:\r\n` +
            `FN:\r\n` +
            `REV:${new Date()}\r\n` +
            "END:VCARD",
          filename: `${contact.id.value}.vcf`,
          etag: "an-etag",
          url: "a-url",
        }))
      )
    return new this(new NullDavClient({ cards }), addressBook)
  }

  static async create(config: Credentials): Promise<Contacts> {
    const dav = await Fastmail.createDavClient(config)
    const addressBooks = await dav.fetchAddressBooks()
    return new this(dav, addressBooks[0])
  }

  private constructor(
    private readonly dav: DavClient,
    private readonly addressBook: DavAddressBook
  ) {}

  async createGroupNamed(group: ContactsGroupName) {
    const uuid = crypto.randomUUID()
    const rev = new Date().toISOString()
    const result = await this.dav.createVCard({
      addressBook: this.addressBook,
      vCardString:
        "BEGIN:VCARD\r\n" +
        "VERSION:3.0\r\n" +
        `UID:${uuid}\r\n` +
        `N:${group.value}\r\n` +
        `FN:${group.value}\r\n` +
        "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
        `REV:${rev}\r\n` +
        "END:VCARD",
      filename: `${uuid}.vcf`,
    })
    if (!result.ok) {
      throw new Error(result.statusText)
    }
    this.emit({
      action: "create-group",
      group,
    })
  }

  async createContact(emailAddress: EmailAddress) {
    const uuid = crypto.randomUUID()
    const rev = new Date().toISOString()
    const result = await this.dav.createVCard({
      addressBook: this.addressBook,
      vCardString:
        "BEGIN:VCARD\r\n" +
        "VERSION:3.0\r\n" +
        `UID:${uuid}\r\n` +
        `EMAIL:${emailAddress}\r\n` +
        `N:\r\n` +
        `FN:\r\n` +
        `REV:${rev}\r\n` +
        "END:VCARD",
      filename: `${uuid}.vcf`,
    })
    if (!result.ok) {
      throw new Error(result.statusText)
    }
    this.emit({
      action: "create-contact",
      emailAddress,
    })
  }

  async groups(): Promise<ContactsGroup[]> {
    // TODO: figure out how to use filters in the query for efficiency?
    const cards = await this.dav.fetchVCards({ addressBook: this.addressBook })
    const groups = cards.filter((card) =>
      card.data?.match(/X-ADDRESSBOOKSERVER-KIND:group\r\n/)
    )
    return groups.map((group) => parseDavGroup(group.data || ""))
  }

  async contacts(): Promise<Contact[]> {
    const cards = await this.dav.fetchVCards({ addressBook: this.addressBook })
    const contacts = cards.filter(
      (card) => !card.data?.match(/X-ADDRESSBOOKSERVER-KIND:group\r\n/)
    )
    return contacts.map((contact) => parseDavContact(contact.data || ""))
  }

  async addToGroup(from: EmailAddress, groupName: ContactsGroupName) {
    const group = (await this.groups()).find((group) =>
      group.name.equals(groupName)
    )
    if (!group) throw new Error("Group does not exist!")
    const contact = (await this.contacts()).find((contact) =>
      contact.email.equals(from)
    )
    if (!contact) throw new Error("Contact does not exist!")
    const rev = new Date().toISOString()
    const result = await this.dav.updateVCard({
      vCard: {
        data:
          "BEGIN:VCARD\r\n" +
          "VERSION:3.0\r\n" +
          `UID:${group.id.value}\r\n` +
          `N:${groupName.value}\r\n` +
          `FN:${groupName.value}\r\n` +
          "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
          `X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:${contact.id.value}\r\n` +
          `REV:${rev}\r\n` +
          "END:VCARD",
        // TODO: remember URL from when we look up the group before
        url: `https://carddav.fastmail.com/dav/addressbooks/user/test@levain.codes/Default/${group.id.value}.vcf`,
        etag: "",
      },
    })
    if (!result.ok) {
      throw new Error(result.statusText)
    }
    this.emit({
      action: "add-to-group",
      emailAddress: from,
      group: groupName,
    })
  }

  trackChanges(): OutputTracker<ContactsChange> {
    return OutputTracker.create<ContactsChange>(this.emitter, CHANGE_EVENT)
  }

  private emit(event: ContactsChange) {
    this.emitter.emit(CHANGE_EVENT, ContactsChange.of(event))
  }
}
