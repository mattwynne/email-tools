import { Email } from "../core/Email"
import { EmailAddress } from "../core/EmailAddress"
import { EmailSubject } from "../core/EmailSubject"
import { Mailbox } from "../core/Mailbox"
import { MailboxName } from "../core/MailboxName"
import { MailboxState } from "../core/MailboxState"

const defaultNullConfiguration = {
  mailboxState: new MailboxState([]),
}

type NullEmailProviderConfiguration = {
  mailboxState: MailboxState
}

interface EmailAccount {
  getMailboxState: () => Promise<MailboxState>
}

class NullEmailAccount implements EmailAccount {
  constructor(private readonly mailboxState: MailboxState) {}

  async getMailboxState() {
    return this.mailboxState
  }
}

export type FastmailConfig = {
  token: string
}

type ApiMethod =
  | "Email/get"
  | "Email/changes"
  | "Email/query"
  | "Email/queryChanges"
  | "Thread/changes"
  | "Thread/get"
  | "Mailbox/changes"
  | "Mailbox/get"

class FastmailEmailAccount implements EmailAccount {
  constructor(private readonly api: FastmailSession) {}

  private async getEmailsIn(mailboxId: string): Promise<Email[]> {
    const ids = (
      await this.api.call("Email/query", {
        accountId: this.api.accountId,
        filter: {
          inMailbox: mailboxId,
        },
      })
    ).ids
    const emails = (
      await this.api.call("Email/get", {
        accountId: this.api.accountId,
        ids,
      })
    ).list
    return emails.map((email: { subject: string; from: { email: string }[] }) =>
      Email.from(EmailAddress.of(email.from[0].email)).about(
        EmailSubject.of(email.subject)
      )
    )
  }

  private async getMailboxes(): Promise<Mailbox[]> {
    return Promise.all(
      (
        await this.api.call("Mailbox/get", {
          accountId: this.api.accountId,
          ids: null,
        })
      ).list.map(
        async (mailbox: { id: string; name: string }) =>
          new Mailbox(
            MailboxName.of(mailbox.name),
            await this.getEmailsIn(mailbox.id)
          )
      )
    )
  }

  async getMailboxState() {
    const mailboxes = await this.getMailboxes()
    // const inbox = mailboxes.find(
    //   (mailbox) => mailbox.name === MailboxName.of("Inbox")
    // )
    // const inboxChildren = mailboxes.filter(
    //   (mailbox: { parentId: string }) => mailbox.parentId === inbox.id
    // )
    return new MailboxState(mailboxes)
  }
}

class FastmailSession {
  static async create(token: string) {
    const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    }
    const hostname = "api.fastmail.com"
    const authUrl = `https://${hostname}/.well-known/jmap`
    const response = await fetch(authUrl, {
      method: "GET",
      headers,
    })
    return new this(headers, (await response.json()) as FastmailSession)
  }

  constructor(
    public readonly headers: { [key: string]: string },
    private readonly data: FastmailSession
  ) {}

  get apiUrl(): string {
    return this.data.apiUrl
  }

  get primaryAccounts(): { [urn: string]: string } {
    return this.data.primaryAccounts
  }

  get accountId(): string {
    return this.data.primaryAccounts["urn:ietf:params:jmap:mail"]
  }

  public async call(method: ApiMethod, params: any) {
    const response = await fetch(this.apiUrl, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
        methodCalls: [[method, params, "a"]],
      }),
    })
    const data = await response.json()
    const result = data["methodResponses"][0][1]
    // console.log(
    //   method,
    //   "params:",
    //   params,
    //   "response:",
    //   util.inspect(result, { depth: Infinity })
    // )
    return result
  }
}

export class EmailProvider {
  static async create(config: FastmailConfig) {
    const session = await FastmailSession.create(config.token)
    return new this(new FastmailEmailAccount(session))
  }

  static createNull({
    mailboxState,
  }: NullEmailProviderConfiguration = defaultNullConfiguration) {
    return new this(new NullEmailAccount(mailboxState))
  }

  constructor(private readonly account: EmailAccount) {}

  getMailboxState() {
    return this.account.getMailboxState()
  }
}
