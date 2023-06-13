#!/usr/bin/env node

import { P } from "pino"
import EventSource from "eventsource"

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
  console.log(method, result)
  return result
}

const emailChanges = async (
  apiUrl: string,
  accountId: string,
  change: string
) => {
  return methodCall(apiUrl, "Email/changes", { accountId, sinceState: change })
}

const emailGet = async (apiUrl: string, accountId: string, id: string) => {
  return methodCall(apiUrl, "Email/get", { accountId, ids: [id] })
}

const run = async () => {
  const session = await getSession()
  console.log(session)
  const apiUrl = session.apiUrl
  const eventsUrl = session.eventSourceUrl
  const accountId = session.primaryAccounts["urn:ietf:params:jmap:mail"]
  let currentState: AccountChanges
  await subscribe(eventsUrl, (accountId: string, changes: AccountChanges) => {
    console.log("Something changed!", "from:", currentState, "to:", changes)
    currentState = changes
    const emailChange = changes.Email

    methodCall(apiUrl, "Thread/changes", {
      accountId,
      sinceState: changes.Thread,
    }).then((result) => {
      if (result.updated.length > 0) {
        methodCall(apiUrl, "Thread/get", { accountId, ids: result.updated })
      }
    })
    methodCall(apiUrl, "Mailbox/changes", {
      accountId,
      sinceState: changes.Mailbox,
    }).then((result) => {
      if (result.updated.length > 0) {
        methodCall(apiUrl, "Mailbox/get", { accountId, ids: result.updated })
      }
    })
    emailChanges(apiUrl, accountId, emailChange).then((result) => {
      if (result.updated.length > 0) {
        emailGet(apiUrl, accountId, result.updated[0])
      }
    })
  })
}

run()
