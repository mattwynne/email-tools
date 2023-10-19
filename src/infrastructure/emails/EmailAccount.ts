import { MailboxName, MailboxState } from "../../core"

export interface EmailAccount {
  onChange: (handler: () => void) => void
  getMailboxState: (onlyMailboxNames?: MailboxName[]) => Promise<MailboxState>
  close: () => void
}
