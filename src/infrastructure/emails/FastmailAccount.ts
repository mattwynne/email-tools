import { EmailAddress, EmailSubject, MailboxName, Mailbox } from "../../core"
import { Email } from "../../core/Email"
import { MailboxState } from "../../core/MailboxState"
import { EmailAccount } from "./EmailAccount"
import { FastmailSession } from "./FastmailSession"

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
        return Email.from(EmailAddress.of(sender))
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
