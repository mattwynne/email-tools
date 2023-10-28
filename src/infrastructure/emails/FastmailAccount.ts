import Debug from "debug"
import {
  Email,
  EmailAddress,
  EmailSubject,
  Mailbox,
  MailboxName,
  MailboxState,
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
    await onReady(account)
    subscriber.close()
  }

  private mailboxState: MailboxState = new MailboxState([])

  constructor(
    private readonly session: FastmailSession,
    private readonly subscriber: Subscriber
  ) {}

  public get state() {
    return this.mailboxState
  }

  public async refresh() {
    const mailboxes = await this.getMailboxes()
    this.mailboxState = new MailboxState(mailboxes)
    return this
  }

  public async onChange(handler: (changes: StateChange) => void) {
    await this.subscriber.addEventListener(handler)
  }

  public async emailsIn(mailboxName: MailboxName): Promise<Email[]> {
    const mailbox = this.mailboxState.mailboxes.find((mailbox) =>
      mailbox.name.equals(mailboxName)
    )
    if (!mailbox) throw new Error(`No mailbox named '${mailboxName}'`)
    return await this.getEmailsIn(mailbox.id)
  }

  private async getMailboxes(): Promise<Mailbox[]> {
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
        `emails-in-mailbox-${id}`,
      ])
    )
    return mailboxes.list.map((mailbox: { id: string; name: string }) =>
      Mailbox.named(mailbox.name)
        .withId(UniqueIdentifier.of(mailbox.id))
        .withEmails(
          emails
            .find(
              (response: [unknown, unknown, string]) =>
                response[2] === `emails-in-mailbox-${mailbox.id}`
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
