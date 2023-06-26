import EventEmitter from "events"
import { OutputTracker } from "./OutputTracker"
import { ContactsGroup } from "../core/ContactsGroup"
import {
  ContactsChange,
  CHANGE_EVENT,
} from "../../features/step_definitions/steps"
import { EmailAddress } from "../core/EmailAddress"

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
