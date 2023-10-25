import {
  Email,
  EmailAddress,
  EmailSubject,
  Mailbox,
  MailboxName,
  MailboxState,
} from "../../core"
import { FastmailConfig, FastmailSession, Subscriber } from "./FastmailSession"

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
    const result = new this(session, subscriber)
    await result.refresh()
    if (onReady) {
      await onReady(result)
      subscriber.close()
    }
  }

  private currentState: MailboxState = new MailboxState([])

  constructor(
    private readonly session: FastmailSession,
    private readonly subscriber: Subscriber
  ) {}

  public get state() {
    return this.currentState
  }

  public async refresh() {
    const mailboxes = await this.getMailboxes()
    this.currentState = new MailboxState(mailboxes)
    return this
  }

  public async onChange(handler: () => void) {
    await this.subscriber.addEventListener(handler)
  }

  private async getMailboxes(
    onlyMailboxes?: MailboxName[]
  ): Promise<Mailbox[]> {
    const filter = onlyMailboxes
      ? (mailbox: { name: string }) =>
          onlyMailboxes.some((name) =>
            name.equals(MailboxName.of(mailbox.name))
          )
      : () => true

    return Promise.all(
      (
        await this.session.call("Mailbox/get", {
          accountId: this.session.accountId,
          ids: null,
        })
      ).list
        .filter(filter)
        .map(async (mailbox: { id: string; name: string }) =>
          Mailbox.named(mailbox.name).withEmails(
            await this.getEmailsIn(mailbox.id)
          )
        )
    )
  }

  private async getEmailsIn(mailboxId: string): Promise<Email[]> {
    const result = await this.session.calls([
      [
        "Email/query",
        {
          accountId: this.session.accountId,
          filter: {
            inMailbox: mailboxId,
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
          console.error(error)
          return Email.from(EmailAddress.of("unknown"))
        }
      }
    )
  }
}
