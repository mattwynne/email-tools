import { Contacts } from "./infrastructure/contacts"
import { MailboxState } from "./core/MailboxState"
import { FastmailAccount } from "./infrastructure/emails"

export class Application {
  private currentState?: MailboxState

  constructor(
    private readonly emailAccount: FastmailAccount,
    private readonly contactsProvider: Contacts
  ) {}

  async processNewMailboxState() {
    const state = await this.emailAccount.state
    if (this.currentState) {
      await this.contactsProvider.addToGroup(
        state.mailboxes[0].emails[0].from,
        state.mailboxes[0].name.contactsGroup
      )
    }
    this.currentState = state
    return this
  }
}
