import { MailboxName } from "../../core/MailboxName"
import { MailboxState } from "../../core/MailboxState"

export interface EmailAccount {
  getMailboxState: (onlyMailboxNames?: MailboxName[]) => Promise<MailboxState>
}
