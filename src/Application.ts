import { ContactsProvider } from "./infrastructure/ContactsProvider"
import { MailboxState } from "./core/MailboxState"
import { EmailProvider } from "./infrastructure/EmailProvider"

export class Application {
  private currentState?: MailboxState

  constructor(
    private readonly emailProvider: EmailProvider,
    private readonly contactsProvider: ContactsProvider
  ) {}

  processNewMailboxState(state: MailboxState) {
    if (this.currentState) {
      this.contactsProvider.addToGroup(
        state.mailboxes[0].emails[0].from,
        state.mailboxes[0].name.contactsGroup
      )
    }
    this.currentState = state
  }
}
