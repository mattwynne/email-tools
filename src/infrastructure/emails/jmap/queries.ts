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

export const getMailboxChangesSince = async (
  session: FastmailSession,
  sinceState: string
) => {
  const { accountId } = session
  const result = await session.calls([
    [
      "Mailbox/changes",
      {
        accountId,
        sinceState,
      },
      "changes",
    ],
    // Fetch any mailboxes that have been created
    [
      "Mailbox/get",
      {
        accountId,
        "#ids": {
          name: "Mailbox/changes",
          path: "/created",
          resultOf: "changes",
        },
      },
      "created",
    ],
    // Fetch any mailboxes that have been updated
    [
      "Mailbox/get",
      {
        accountId,
        "#ids": {
          name: "Mailbox/changes",
          path: "/updated",
          resultOf: "changes",
        },
        "#properties": {
          name: "Mailbox/changes",
          path: "/updatedProperties",
          resultOf: "changes",
        },
      },
      "updated",
    ],
  ])
  debug(result)
  return result as [
    ["Mailbox/changes", JmapMailboxChangesResult, "changes"],
    ["Mailbox/get", JmapMailboxGetResult, "created"],
    ["Mailbox/get", JmapMailboxGetResult, "updated"]
  ]
}

type JmapMailboxChangesResult = {
  oldState: string
  newState: string
  updatedProperties: string[]
  destroyed: JmapMailboxId[]
  updated: JmapMailboxId[]
  created: JmapMailboxId[]
}

type JmapMailboxGetResult = {
  list: JmapMailbox[]
  state: string
}

type JmapMailbox = {
  id: JmapMailboxId
  name: string
  totalEmails: number
  unreadEmails: number
  parentId: JmapMailboxId | null
}

export const emailQueryChanges = async (
  session: FastmailSession,
  mailboxes: { id: JmapMailboxId }[],
  sinceQueryState: string
): Promise<JmapEmailQueryChangesResult> => {
  const result = await session.calls(
    mailboxes.map(({ id }) => [
      "Email/queryChanges",
      {
        accountId: session.accountId,
        sinceQueryState,
        filter: { inMailbox: id },
        sort: [{ property: "receivedAt", isAscending: false }],
      },
      id,
    ])
  )
  debug(result)
  return result as JmapEmailQueryChangesResult
}

export const emailChanges = async (
  session: FastmailSession,
  sinceState: string
): Promise<JmapEmailChanges> => {
  return await session.call("Email/changes", {
    accountId: session.accountId,
    sinceState,
  })
}

type JmapEmailChanges = {
  oldState: string
  newState: string
  created: JmapEmailId[]
  updated: JmapEmailId[]
  destroyed: JmapEmailId[]
}

export const getEmailsInMailboxes = async (
  session: FastmailSession,
  mailboxes: { id: JmapMailboxId }[]
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
  ids: JmapEmailId[]
  queryState: string
  filter: {
    inMailbox: JmapMailboxId
  }
}

type JmapEmailQueryChangesResult = {}

type JmapEmailId = string
type JmapMailboxId = string
