import Debug from "debug"
import { FastmailSession } from "../FastmailSession"

const debug = Debug("email-tools:jmap/queries")

export const getAllMailboxes = async (session: FastmailSession) => {
  const mailboxes = await session.call("Mailbox/get", {
    accountId: session.accountId,
    ids: null,
  })
  debug(mailboxes)
  return mailboxes as JmapMailboxGetResult
}

type JmapMailboxGetResult = {
  list: JmapMailbox[]
  state: string
}

type JmapMailbox = {
  id: string
  name: string
  totalEmails: number
  unreadEmails: number
  parentId: string | null
}

export const getEmailsInMailboxes = async (
  session: FastmailSession,
  mailboxes: JmapMailbox[]
): Promise<JmapEmailQueryResult[]> => {
  const emails = await session.calls(
    mailboxes.map(({ id }) => [
      "Email/query",
      {
        accountId: session.accountId,
        filter: {
          inMailbox: id,
        },
      },
      id,
    ])
  )
  debug(emails)
  return emails.map(
    (response: [string, JmapEmailQueryResult]) =>
      response[1] as JmapEmailQueryResult
  )
}

type JmapEmailQueryResult = {
  ids: string[]
  queryState: string
  filter: {
    inMailbox: string
  }
}
