import { Contacts } from "./infrastructure/Contacts"
import { MailboxState } from "./Core/MailboxState"
import { EmailProvider } from "./infrastructure/Emails"

export class Application {
  private currentState?: MailboxState

  constructor(
    private readonly emailProvider: EmailProvider,
    private readonly contactsProvider: Contacts
  ) {}

  async processNewMailboxState() {
    const state = await this.emailProvider.getMailboxState()
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
