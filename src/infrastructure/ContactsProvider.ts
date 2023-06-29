import EventEmitter from "events"
import { OutputTracker } from "./OutputTracker"
import { ContactsGroup } from "../core/ContactsGroup"
import { ContactsChange } from "./ContactsChange"
import { EmailAddress } from "../core/EmailAddress"

export const CHANGE_EVENT = "change"

export class ContactsProvider {
  private readonly emitter = new EventEmitter()

  static createNull() {
    return new this()
  }

  addToGroup(from: EmailAddress, contactGroup: ContactsGroup) {}

  trackChanges(): OutputTracker<ContactsChange> {
    return OutputTracker.create<ContactsChange>(this.emitter, CHANGE_EVENT)
  }
}
