import Debug from "debug"
import {
  Email,
  EmailAddress,
  EmailSubject,
  MailboxState,
  MailboxName,
  EmailAccountState,
  UniqueIdentifier,
} from "../../core"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import { StateChange, Subscriber } from "./Subscriber"
import { EventEmitter } from "stream"

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
    const subscriber = await session.connectSubscriber()
    const account = new FastmailAccount(session, subscriber)
    await account.refreshed()
    try {
      await onReady(account)
    } finally {
      subscriber.close()
    }
  }

  private accountState: EmailAccountState = new EmailAccountState([])
  private changes: StateChange[] = []
  private events = new EventEmitter()

  private constructor(
    private readonly session: FastmailSession,
    private readonly subscriber: Subscriber
  ) {
    this.subscriber.addEventListener((changes) => {
      this.changes.push(changes)
      this.refresh().then(() => {
        this.events.emit("refreshed")
      })
    })
  }

  public async refreshed() {
    return new Promise((resolve) => this.events.on("refreshed", resolve))
  }

  public get state() {
    return this.accountState
  }

  private async refresh() {
    const mailboxes = await this.getMailboxes()
    this.accountState = new EmailAccountState(mailboxes)
    return this
  }

  public async onChange(handler: (changes: StateChange) => void) {
    await this.subscriber.addEventListener(handler)
  }

  public async emailsIn(mailboxName: MailboxName): Promise<Email[]> {
    const mailbox = this.accountState.mailboxes.find((mailbox) =>
      mailbox.name.equals(mailboxName)
    )
    if (!mailbox) throw new Error(`No mailbox named '${mailboxName}'`)
    return await this.getEmailsIn(mailbox.id)
  }

  private async getMailboxes(): Promise<MailboxState[]> {
    const mailboxes = await this.session.call("Mailbox/get", {
      accountId: this.session.accountId,
      ids: null,
    })

    const mailboxIds = mailboxes.list.map(({ id }: { id: string }) => id)

    const emails = await this.session.calls(
      mailboxIds.map((inMailbox: string) => [
        "Email/query",
        {
          accountId: this.session.accountId,
          filter: {
            inMailbox,
          },
        },
        inMailbox,
      ])
    )
    return mailboxes.list.map((mailbox: { id: string; name: string }) =>
      MailboxState.named(mailbox.name)
        .withId(UniqueIdentifier.of(mailbox.id))
        .withEmailIds(
          emails
            .find(
              (
                response: [unknown, { filter: { inMailbox: string } }, unknown]
              ) => response[1].filter.inMailbox === mailbox.id
            )[1]
            .ids.map((id: string) => UniqueIdentifier.of(id))
        )
    )
  }

  private async getEmailsIn(mailboxId: UniqueIdentifier): Promise<Email[]> {
    const result = await this.session.calls([
      [
        "Email/query",
        {
          accountId: this.session.accountId,
          filter: {
            inMailbox: mailboxId.value,
          },
        },
        "0",
      ],
      [
        "Email/get",
        {
          accountId: this.session.accountId,
          "#ids": {
            resultOf: "0",
            name: "Email/query",
            path: "/ids",
          },
        },
        "1",
      ],
    ])
    const emails = result[1][1].list
    if (!emails) {
      throw new Error("No emails found for mailbox " + mailboxId)
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
