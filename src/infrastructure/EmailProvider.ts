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
  getMailboxState: (onlyMailboxNames?: MailboxName[]) => Promise<MailboxState>
}

class NullEmailAccount implements EmailAccount {
  constructor(private readonly mailboxState: MailboxState) {}

  async getMailboxState(onlyMailboxNames?: MailboxName[]) {
    if (!onlyMailboxNames) return this.mailboxState
    return new MailboxState(
      this.mailboxState.mailboxes.filter((mailbox) =>
        onlyMailboxNames.some((name) => name.equals(mailbox.name))
      )
    )
  }
}

export type FastmailConfig = {
  token: string
}

type ApiMethod =
  | "Email/get"
  | "Email/set"
  | "Email/query"
  | "Mailbox/get"
  | "Mailbox/set"
  | "Mailbox/query"

type MethodCall = [method: ApiMethod, params: any, index: string]

export class FastmailAccount implements EmailAccount {
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
    if (!emails) {
      throw new Error("No emails found for mailbox " + mailboxId)
    }
    return emails.map(
      (email: { subject: string; from: { email: string }[] }) => {
        const sender = email.from ? email.from[0].email : "unknown@example.com"
        return Email.from(EmailAddress.of(sender)).about(
          EmailSubject.of(email.subject)
        )
      }
    )
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
        await this.api.call("Mailbox/get", {
          accountId: this.api.accountId,
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

  async getMailboxState(onlyMailboxes?: MailboxName[]) {
    const mailboxes = await this.getMailboxes(onlyMailboxes)
    // const inbox = mailboxes.find(
    //   (mailbox) => mailbox.name === MailboxName.of("Inbox")
    // )
    // const inboxChildren = mailboxes.filter(
    //   (mailbox: { parentId: string }) => mailbox.parentId === inbox.id
    // )
    return new MailboxState(mailboxes)
  }
}

export class FastmailSession {
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

  get username(): string {
    return this.data.username
  }

  get primaryAccounts(): { [urn: string]: string } {
    return this.data.primaryAccounts
  }

  get accountId(): string {
    return this.data.primaryAccounts["urn:ietf:params:jmap:mail"]
  }

  public async call(method: ApiMethod, params: any) {
    const responses = await this.calls([[method, params, "0"]])
    return responses[0][1]
  }

  public async calls(methodCalls: MethodCall[]) {
    const response = await fetch(this.apiUrl, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify({
        using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
        methodCalls,
      }),
    })
    if (!response.ok) {
      throw new Error(await response.text())
    }
    const result = await response.json()
    // console.log(util.inspect({ methodCalls, result }, { depth: Infinity }))
    return result["methodResponses"]
  }
}

export class EmailProvider {
  static async create(config: FastmailConfig) {
    const session = await FastmailSession.create(config.token)
    return new this(new FastmailAccount(session))
  }

  static createNull({
    mailboxState,
  }: NullEmailProviderConfiguration = defaultNullConfiguration) {
    return new this(new NullEmailAccount(mailboxState))
  }

  constructor(private readonly account: EmailAccount) {}

  getMailboxState(onlyMailboxNames?: MailboxName[]) {
    return this.account.getMailboxState(onlyMailboxNames)
  }
}
