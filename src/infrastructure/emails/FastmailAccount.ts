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
import {
  getAllMailboxes,
  emailQueryChanges,
  getEmailsInMailboxes,
  getMailboxChangesSince,
  emailChanges,
} from "./jmap/queries"

const debug = Debug("email-tools:FastmailAccount")

type EventMap = Record<string, any>
type EventKey<Map extends EventMap> = string & keyof Map
type EventReceiver<T> = (params: T) => void
interface Emitter<T extends EventMap> {
  on<Key extends EventKey<T>>(eventName: Key, fn: EventReceiver<T[Key]>): void
  off<Key extends EventKey<T>>(eventName: Key, fn: EventReceiver<T[Key]>): void
  emit<Key extends EventKey<T>>(eventName: Key, params: T[Key]): void
}

function createEmitter<T extends EventMap>(): Emitter<T> {
  return new EventEmitter()
}

type Events = {
  "email-created": EmailCreatedEvent
}

export type EmailCreatedEvent = {
  email: Email
}

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
  public events: Emitter<Events> = new EventEmitter()

  private constructor(private readonly session: FastmailSession) {}

  public get state() {
    return this.accountState
  }

  private async refresh(newState: StateChange) {
    debug("Refreshing with state", newState)
    const accountStateChanges = newState.changed[this.session.accountId]
    if (this.accountState.mailboxState == "") {
      this.accountState = new EmailAccountState(
        await this.getMailboxes(),
        accountStateChanges.Mailbox,
        accountStateChanges.Email
      )
    } else {
      const mailboxChanges = await getMailboxChangesSince(
        this.session,
        this.accountState.mailboxState
      )
      debug(mailboxChanges)
      const updatedMailboxEmails = await emailQueryChanges(
        this.session,
        mailboxChanges[2][1].list,
        this.accountState.emailState + ":0"
      )
      debug(updatedMailboxEmails)
      const changes = await emailChanges(
        this.session,
        this.accountState.emailState
      )
      debug(changes)
      const createdEmails = await this.session.call("Email/get", {
        accountId: this.session.accountId,
        ids: changes.created,
      })
      for (const email of createdEmails.list) {
        this.events.emit("email-created", { email })
      }
    }
    return this
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
