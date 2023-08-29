import { MailboxName } from "../../core/MailboxName"
import { MailboxState } from "../../core/MailboxState"
import { EmailAccount } from "./EmailAccount"
import { FastmailAccount } from "./FastmailAccount"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import { NullEmailAccount } from "./NullEmailAccount"

export class EmailProvider {
  static async create(config: FastmailConfig) {
    const session = await FastmailSession.create(config.token)
    return new this(new FastmailAccount(session))
  }

  static createNull(config?: { mailboxStates?: MailboxState[] }) {
    const { mailboxStates } = { mailboxStates: [], ...config }
    return new this(new NullEmailAccount(mailboxStates.slice()))
  }

  constructor(private readonly account: EmailAccount) {}

  getMailboxState(onlyMailboxNames?: MailboxName[]) {
    return this.account.getMailboxState(onlyMailboxNames)
  }
}
