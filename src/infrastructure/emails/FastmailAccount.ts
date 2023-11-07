import Debug from "debug"
import { EventEmitter } from "stream"
import {
  Email,
  EmailAccountState,
  EmailAddress,
  EmailSubject,
  MailboxName,
  MailboxState,
  UniqueIdentifier,
} from "../../core"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import { PushNotification, StateChange } from "./PushNotification"
import { getAllMailboxes, getEmailsInMailboxes } from "./jmap/queries"

const debug = Debug("email-tools:FastmailAccount")

export class FastmailAccount {
  static createNull(arg?: any): FastmailAccount {
    throw new Error("Method not implemented.")
  }

  static async connect(
    config: FastmailConfig,
    onReady: (account: FastmailAccount) => Promise<void>
  ) {
    const session = await FastmailSession.create(config.token)
    const pushNotifications = await PushNotification.connect(session)
    const account = new FastmailAccount(session)
    await account.refresh(pushNotifications.state)
    pushNotifications.addEventListener((changes) => account.refresh(changes))
    try {
      await onReady(account)
    } finally {
      pushNotifications.close()
    }
  }

  private accountState: EmailAccountState = new EmailAccountState([], "", "")
  private changes: StateChange[] = []
  private events = new EventEmitter()

  private constructor(private readonly session: FastmailSession) {}

  public get state() {
    return this.accountState
  }

  private async refresh(newState: StateChange) {
    debug("Refreshing with state", newState)
    const mailboxes = await this.getMailboxes()
    this.accountState = new EmailAccountState(
      mailboxes,
      newState.changed[this.session.accountId].Mailbox,
      newState.changed[this.session.accountId].Email
    )
    this.events.emit("refreshed")
    return this
  }

  public async onChange(handler: () => void) {
    this.events.on("refreshed", () => handler())
  }

  public async emailsIn(mailboxName: MailboxName): Promise<Email[]> {
    const mailbox = this.accountState.mailboxes.find((mailbox) =>
      mailbox.name.equals(mailboxName)
    )
    if (!mailbox) throw new Error(`No mailbox named '${mailboxName}'`)
    return await this.getEmailsIn(mailbox)
  }

  private async getMailboxes(): Promise<MailboxState[]> {
    const mailboxes = await getAllMailboxes(this.session)
    const emails = await getEmailsInMailboxes(this.session, mailboxes.list)
    return mailboxes.list.map((mailbox) =>
      MailboxState.named(mailbox.name)
        .withId(UniqueIdentifier.of(mailbox.id))
        .withEmailIds(
          emails
            .find((queryResult) => queryResult.filter.inMailbox === mailbox.id)
            ?.ids.map((id) => UniqueIdentifier.of(id)) || []
        )
    )
  }

  private async getEmailsIn(mailbox: MailboxState): Promise<Email[]> {
    const result = await this.session.call("Email/get", {
      accountId: this.session.accountId,
      ids: mailbox.emailIds.map((id) => id.value),
    })
    const emails = result.list
    if (!emails) {
      throw new Error("No emails found for mailbox " + mailbox.name)
    }
    return emails.map(
      (email: { subject: string; from: { email: string }[] }) => {
        try {
          const sender = email.from
            ? email.from[0].email
            : "unknown@example.com"
          return Email.from(EmailAddress.of(sender)).about(
            EmailSubject.of(email.subject || "")
          )
        } catch (error) {
          return Email.from(EmailAddress.of("unknown"))
        }
      }
    )
  }
}
