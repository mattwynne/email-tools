import { EmailAddress, MailboxName, Mailbox, EmailSubject } from "../../core"
import { Email } from "../../core/Email"
import { MailboxState } from "../../core/MailboxState"
import { EmailAccount } from "./EmailAccount"
import { FastmailSession } from "./FastmailSession"

// TODO: too many layers with the Provider, Account and Session. Need to flatten this somehow.
export class FastmailAccount implements EmailAccount {
  constructor(private readonly api: FastmailSession) {}

  public onChange(handler: () => void) {
    this.api.subscribe(handler)
  }

  public close() {
    this.api.close()
  }

  private async getEmailsIn(mailboxId: string): Promise<Email[]> {
    const result = await this.api.calls([
      [
        "Email/query",
        {
          accountId: this.api.accountId,
          filter: {
            inMailbox: mailboxId,
          },
        },
        "0",
      ],
      [
        "Email/get",
        {
          accountId: this.api.accountId,
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
