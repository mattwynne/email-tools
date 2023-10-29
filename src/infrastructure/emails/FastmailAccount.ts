import Debug from "debug"
import {
  Email,
  EmailAddress,
  EmailSubject,
  Mailbox,
  MailboxName,
  EmailAccountState,
  UniqueIdentifier,
} from "../../core"
import { FastmailConfig, FastmailSession } from "./FastmailSession"
import { StateChange, Subscriber } from "./Subscriber"

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
    const subscriber = await session.subscribe()
    const account = new this(session, subscriber)
    const changes = await new Promise((resolve) =>
      subscriber.addEventListener((changes) => resolve(changes))
    )
    debug(changes)
    await account.refresh()
    try {
      await onReady(account)
    } finally {
      subscriber.close()
    }
  }

  private accountState: EmailAccountState = new EmailAccountState([])
  private changes: StateChange[] = []

  constructor(
    private readonly session: FastmailSession,
    private readonly subscriber: Subscriber
  ) {
    this.subscriber.addEventListener((changes) => {
      this.changes.push(changes)
      this.refresh()
    })
  }

  public get state() {
    return this.accountState
  }

  public async refresh() {
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

  private async getMailboxes(): Promise<Mailbox[]> {
    if (this.changes.length > 1) {
      const previousChange = this.changes[this.changes.length - 2]
      const result = await this.session.calls(
        this.accountState.mailboxes.map((mailbox) => [
          "Email/queryChanges",
          {
            accountId: this.session.accountId,
            filter: {
              inMailbox: mailbox.id.value,
            },
            sinceQueryState: `${
              previousChange.changed[this.session.accountId].Email
            }:0`,
          },
          mailbox.id.value,
        ])
      )
      debug(result)
      for (const queryChanges of result) {
        if (queryChanges.added.length > 0) {
          debug("added: ", queryChanges.added)
        }
        if (queryChanges.removed.length > 0) {
          debug("removed: ", queryChanges.removed)
        }
      }
    }
    const mailboxes = await this.session.call("Mailbox/get", {
      accountId: this.session.accountId,
      ids: null,
    })

    const ids = mailboxes.list.map(({ id }: { id: string }) => id)

    const emails = await this.session.calls(
      ids.map((id: string) => [
        "Email/query",
        {
          accountId: this.session.accountId,
          filter: {
            inMailbox: id,
          },
        },
        id,
      ])
    )
    return mailboxes.list.map((mailbox: { id: string; name: string }) =>
      Mailbox.named(mailbox.name)
        .withId(UniqueIdentifier.of(mailbox.id))
        .withEmails(
          emails
            .find(
              (
                response: [unknown, { filter: { inMailbox: string } }, unknown]
              ) => response[1].filter.inMailbox === mailbox.id
            )[1]
            .ids.map((id: string) => Email.withId(UniqueIdentifier.of(id)))
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
