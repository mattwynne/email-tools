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

type StateChange = {
  [accountId: string]: {
    Email: string
  }
}

const subscribe = async (
  url: string,
  onChange: (accountId: string, emailChange: string) => void
) =>
  new Promise((resolve) => {
    console.log("Connecting to " + url)
    const source = new EventSource(url + "types=*", { headers })
    source.addEventListener("state", (e) => {
      const changes: StateChange = JSON.parse(e.data).changed
      console.log("StateChange event", changes)
      for (const accountId in changes) {
        const email = changes[accountId].Email
        onChange(accountId, email)
      }
    })
    source.onerror = (e) => console.error("error!", e)
  })

const emailChanges = async (
  apiUrl: string,
  accountId: string,
  change: string
) => {
  const response = await fetch(apiUrl, {
    method: "POST",
    headers,
    body: JSON.stringify({
      using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
      methodCalls: [["Email/changes", { accountId, sinceState: change }, "a"]],
    }),
  })
  const data = await response.json()

  return await data["methodResponses"][0][1]
}

const emailGet = async (apiUrl: string, accountId: string, id: string) => {
  const response = await fetch(apiUrl, {
    method: "POST",
    headers,
    body: JSON.stringify({
      using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
      methodCalls: [["Email/get", { accountId, ids: [id] }, "a"]],
    }),
  })
  const data = await response.json()

  return await data["methodResponses"][0][1]
}

const run = async () => {
  const session = await getSession()
  console.log(session)
  const apiUrl = session.apiUrl
  const eventsUrl = session.eventSourceUrl
  const accountId = session.primaryAccounts["urn:ietf:params:jmap:mail"]
  await subscribe(eventsUrl, (accountId: string, emailChange: string) => {
    emailChanges(apiUrl, accountId, emailChange).then((result) => {
      console.log("Email/changes", result)
      if (result.updated.length > 0) {
        emailGet(apiUrl, accountId, result.updated[0]).then(
          (getEmailResult) => {
            console.log("Email/get", getEmailResult.list)
          }
        )
      }
    })
  })
}

run()
