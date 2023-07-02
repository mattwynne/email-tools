import { MailboxState } from "../core/MailboxState"

const defaultNullConfiguration = {
  mailboxState: new MailboxState([]),
}

type NullEmailProviderConfiguration = {
  mailboxState: MailboxState
}

export class EmailProvider {
  static createNull({
    mailboxState,
  }: NullEmailProviderConfiguration = defaultNullConfiguration) {
    return new this()
  }
}
