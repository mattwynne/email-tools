import EventEmitter from "events"
import { DAVClient } from "tsdav"
import { ContactsGroup } from "../core/ContactsGroup"
import { EmailAddress } from "../core/EmailAddress"
import { ContactsChange } from "./ContactsChange"
import { Environment } from "./Environment"
import { OutputTracker } from "./OutputTracker"
import { parseDavGroup } from "./parseDavGroup"

export const CHANGE_EVENT = "change"

type DavAddressBook = { url: string }

type DavClient = {
  createVCard: (params: {
    addressBook: DavAddressBook
    filename: string
    vCardString: string
  }) => Promise<DavResponse>

  fetchVCards: (params: { addressBook: DavAddressBook }) => Promise<DavObject[]>
}

type DavResponse = {
  ok: boolean
  statusText: string
}

type DavObject = { data?: string }

class NullDavClient implements DavClient {
  public async createVCard({ vCardString }: { vCardString: string }) {
    if (vCardString.match(/fail/i)) {
      return Promise.resolve({ ok: false, statusText: "Failure" })
    }
    return Promise.resolve({ ok: true, statusText: "OK" })
  }

  public async fetchVCards() {
    return Promise.resolve([])
  }
}

class NullDavAddressBook implements DavAddressBook {
  public url: string = "https://whatever.com"
}

interface Credentials {
  username: string
  password: string
}

export class FastmailCredentials implements Credentials {
  static create(env: Environment = Environment.create()) {
    return new this(env.FASTMAIL_USERNAME, env.FASTMAIL_DAV_PASSWORD)
  }

  static createNull(env: Environment = Environment.createNull()) {
    return this.create(env)
  }

  private constructor(
    public readonly username: string,
    public readonly password: string
  ) {}
}

export class Contacts {
  private readonly emitter = new EventEmitter()

  static createNull() {
    return new this(new NullDavClient(), new NullDavAddressBook())
  }

  static async create(config: Credentials): Promise<Contacts> {
    const dav = new DAVClient({
      authMethod: "Basic",
      serverUrl: `https://carddav.fastmail.com/dav/addressbooks/user/${config.username}/Default`,
      credentials: {
        username: config.username.replace("@", "+Default@"),
        password: config.password,
      },
      defaultAccountType: "carddav",
    })
    await dav.login()
    const addressBooks = await dav.fetchAddressBooks()
    return new this(dav, addressBooks[0])
  }

  private constructor(
    private readonly dav: DavClient,
    private readonly addressBook: DavAddressBook
  ) {}

  async createGroup(contactsGroup: ContactsGroup) {
    const uuid = crypto.randomUUID()
    const rev = new Date().toISOString()
    const result = await this.dav.createVCard({
      addressBook: this.addressBook,
      vCardString:
        "BEGIN:VCARD\r\n" +
        "VERSION:3.0\r\n" +
        `UID:${uuid}\r\n` +
        `N:${contactsGroup.value}\r\n` +
        `FN:${contactsGroup.value}\r\n` +
        "X-ADDRESSBOOKSERVER-KIND:group\r\n" +
        `REV:${rev}\r\n` +
        "END:VCARD",
      filename: `${uuid}.vcf`,
    })
    if (!result.ok) {
      throw new Error(result.statusText)
    }
    // TODO: raise event too
  }

  async createContact(email: EmailAddress) {
    const uuid = crypto.randomUUID()
    const rev = new Date().toISOString()
    const result = await this.dav.createVCard({
      addressBook: this.addressBook,
      vCardString:
        "BEGIN:VCARD\r\n" +
        "VERSION:3.0\r\n" +
        `UID:${uuid}\r\n` +
        `EMAIL:${email}\r\n` +
        `N:\r\n` +
        `FN:\r\n` +
        `REV:${rev}\r\n` +
        "END:VCARD",
      filename: `${uuid}.vcf`,
    })
    if (!result.ok) {
      throw new Error(result.statusText)
    }
    // TODO: raise event too
  }

  async groups(): Promise<ContactsGroup[]> {
    const cards = await this.dav.fetchVCards({ addressBook: this.addressBook })
    const groups = cards.filter((card) =>
      card.data?.match(/X-ADDRESSBOOKSERVER-KIND:group\r\n/)
    )
    return groups.map((group) => parseDavGroup(group.data || ""))
  }

  async addToGroup(from: EmailAddress, contactGroup: ContactsGroup) {
    this.emitter.emit(
      CHANGE_EVENT,
      ContactsChange.of({
        action: "add",
        emailAddress: from,
        group: contactGroup,
      })
    )
  }

  trackChanges(): OutputTracker<ContactsChange> {
    return OutputTracker.create<ContactsChange>(this.emitter, CHANGE_EVENT)
  }
}
