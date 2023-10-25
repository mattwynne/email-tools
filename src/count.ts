#!/usr/bin/env node

import fs from "fs/promises"
import { MailboxName } from "./core"
import { FastmailAccount } from "./infrastructure/emails"

const run = async () => {
  const token = process.env.FASTMAIL_API_TOKEN
  if (!token) {
    throw new Error("Please set FASTMAIL_API_TOKEN")
  }
  await FastmailAccount.connect({ token }, async (account) => {
    const { mailboxes } = await account.state.of([
      MailboxName.of("Inbox"),
      MailboxName.of("Paperwork"),
      MailboxName.of("Screener"),
      MailboxName.of("Feed"),
    ])
    console.log(mailboxes)
    const stats = mailboxes.map((mailbox) => ({
      name: mailbox.name,
      messages: mailbox.emails.length,
    }))

    const totals = stats.reduce(
      (totals, stat) => ({
        messages: totals.messages + stat.messages,
      }),
      { messages: 0 }
    )

    const data = {
      date: new Date(),
      totals,
      mailboxes: stats,
    }
    console.log(data)
    const path = __dirname + "/../data/"
    await fs.appendFile(path + "stats.ndjson", JSON.stringify(data) + "\n")
  })
}

run().catch((error) => {
  console.error(error)
  process.exit(1)
})
