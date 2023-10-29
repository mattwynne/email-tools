import { Contacts } from "./infrastructure/contacts"
import { EmailAccountState } from "./core/EmailAccountState"
import { FastmailAccount } from "./infrastructure/emails"

export class Application {
  private currentState?: EmailAccountState

  constructor(
    private readonly emailAccount: FastmailAccount,
    private readonly contactsProvider: Contacts
  ) {}

  async processNewEmailAccountState() {
    const state = await this.emailAccount.state
    if (this.currentState) {
      // await this.contactsProvider.addToGroup(
      //   state.mailboxes[0].emailIds[0].from,
      //   state.mailboxes[0].name.contactsGroup
      // )
    }
    this.currentState = state
    return this
  }
}
