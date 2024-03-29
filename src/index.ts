#!/usr/bin/env node

import EventSource from "eventsource"
import util from "util"

// bail if we don't have our ENV set:
if (!process.env.FASTMAIL_API_TOKEN) {
  console.log("Please set FASTMAIL_API_TOKEN")
  process.exit(1)
}

const hostname = process.env.JMAP_HOSTNAME || "api.fastmail.com"

const authUrl = `https://${hostname}/.well-known/jmap`
const headers = {
  "Content-Type": "application/json",
  Authorization: `Bearer ${process.env.FASTMAIL_API_TOKEN}`,
}

const getSession = async () => {
  const response = await fetch(authUrl, {
    method: "GET",
    headers,
  })
  return response.json()
}

type DataType = "Email" | "Thread" | "Mailbox"

type AccountChanges = { [DT in DataType]: string }

type StateChange = {
  [accountId: string]: AccountChanges
}

const subscribe = async (
  url: string,
  onChange: (accountId: string, changes: AccountChanges) => void
) =>
  new Promise((resolve) => {
    const source = new EventSource(url + "types=*", { headers })
    source.addEventListener("state", (e) => {
      const changes: StateChange = JSON.parse(e.data).changed
      for (const accountId in changes) {
        onChange(accountId, changes[accountId])
      }
    })
    source.onerror = (e) => console.error("error!", e)
  })

type ApiMethod =
  | "Email/get"
  | "Email/changes"
  | "Email/query"
  | "Email/queryChanges"
  | "Thread/changes"
  | "Thread/get"
  | "Mailbox/changes"
  | "Mailbox/get"

const methodCall = async (
  apiUrl: string,
  method: ApiMethod,
  params: Object
) => {
  const response = await fetch(apiUrl, {
    method: "POST",
    headers,
    body: JSON.stringify({
      using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
      methodCalls: [[method, params, "a"]],
    }),
  })
  const data = await response.json()
  const result = data["methodResponses"][0][1]
  console.log(
    method,
    "params:",
    params,
    "response:",
    util.inspect(result, { depth: Infinity })
  )
  return result
}

const handleChanges = async (
  apiUrl: string,
  accountId: string,
  changes: AccountChanges
) => {
  const mailboxChanges = await methodCall(apiUrl, "Mailbox/changes", {
    accountId,
    sinceState: changes.Mailbox,
  })
  if (mailboxChanges.updated.length > 0) {
    const mailboxes = await methodCall(apiUrl, "Mailbox/get", {
      accountId,
      ids: mailboxChanges.updated,
    })
    for (const mailbox of mailboxes.list) {
      console.log(mailbox.name)
    }
  }
  const threadChanges = await methodCall(apiUrl, "Thread/changes", {
    accountId,
    sinceState: changes.Thread,
  })
  if (threadChanges.updated.length > 0) {
    const threads = await methodCall(apiUrl, "Thread/get", {
      accountId,
      ids: threadChanges.updated,
    })
  }
  const emailChanges = await methodCall(apiUrl, "Email/changes", {
    accountId,
    sinceState: changes.Email,
  })
  if (emailChanges.updated.length > 0) {
    const emails = await methodCall(apiUrl, "Email/get", {
      accountId,
      ids: emailChanges.updated,
    })
    for (const email of emails.list) {
      console.log(email.subject)
      const emailQueryChanges = await methodCall(apiUrl, "Email/queryChanges", {
        accountId,
        sinceQueryState: emailChanges.oldState,
        maxChanges: 1,
      })
    }
  }
}

const run = async () => {
  const session = await getSession()
  console.log(session)
  const apiUrl = session.apiUrl
  const eventsUrl = session.eventSourceUrl
  const accountId = session.primaryAccounts["urn:ietf:params:jmap:mail"]
  let currentState: AccountChanges
  const mailboxes = await methodCall(apiUrl, "Mailbox/get", {
    accountId,
    ids: null,
  })
  const inbox = mailboxes.list.find(
    (mailbox: { name: string }) => mailbox.name === "Inbox"
  )
  const inboxChildren = mailboxes.list.filter(
    (mailbox: { parentId: string }) => mailbox.parentId === inbox.id
  )
  const emailsByMailbox = new Map<String, String[]>()
  const mailboxesByEmail = new Map<String, String[]>()
  const inboxes = [inbox, ...inboxChildren]
  for (const mailbox of inboxes) {
    console.log(mailbox.name)
    const emails = await methodCall(apiUrl, "Email/query", {
      accountId,
      filter: {
        inMailbox: mailbox.id,
      },
    })
    emailsByMailbox.set(mailbox.id, emails.ids)
    for (const emailId of emails.ids) {
      if (!mailboxesByEmail.has(emailId))
        mailboxesByEmail.set(
          emailId,
          (mailboxesByEmail.get(emailId) || []).concat([mailbox.id])
        )
    }
  }
  console.log(emailsByMailbox)
  console.log(mailboxesByEmail)
  await subscribe(eventsUrl, (accountId: string, changes: AccountChanges) => {
    console.log("Something changed!", "from:", currentState, "to:", changes)
    currentState = changes
    handleChanges(apiUrl, accountId, changes).catch(console.error)
  })
}

run()
