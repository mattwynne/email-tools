import assert from "node:assert/strict"
import { FastmailSession } from "../FastmailSession"
import { getEmailsInMailboxes } from "./queries"

describe("getEmailsInMailboxes", () => {
  it("matches responses by invocation ID without an echoed filter", async () => {
    const session = {
      accountId: "account-1",
      calls: async (calls: unknown) => {
        assert.deepEqual(calls, [
          [
            "Email/query",
            { accountId: "account-1", filter: { inMailbox: "inbox" } },
            "inbox",
          ],
          [
            "Email/query",
            { accountId: "account-1", filter: { inMailbox: "feed" } },
            "feed",
          ],
        ])
        return [
          ["Email/query", { ids: [], queryState: "state-1" }, "feed"],
          ["Email/query", { ids: ["email-1"], queryState: "state-1" }, "inbox"],
        ]
      },
    } as unknown as FastmailSession

    assert.deepEqual(
      await getEmailsInMailboxes(session, [{ id: "inbox" }, { id: "feed" }]),
      [
        { mailboxId: "feed", ids: [], queryState: "state-1" },
        { mailboxId: "inbox", ids: ["email-1"], queryState: "state-1" },
      ]
    )
  })

  it("does not depend on legacy echoed filters", async () => {
    const session = {
      accountId: "account-1",
      calls: async () => [
        [
          "Email/query",
          {
            ids: ["email-1"],
            queryState: "state-1",
            filter: { inMailbox: "inbox" },
          },
          "inbox",
        ],
      ],
    } as unknown as FastmailSession

    const results = await getEmailsInMailboxes(session, [{ id: "inbox" }])
    assert.equal(results[0].mailboxId, "inbox")
    assert.deepEqual(results[0].ids, ["email-1"])
  })

  it("reports JMAP errors instead of treating them as empty mailboxes", async () => {
    const session = {
      accountId: "account-1",
      calls: async () => [
        ["error", { type: "serverFail", description: "Query failed" }, "inbox"],
      ],
    } as unknown as FastmailSession

    await assert.rejects(
      getEmailsInMailboxes(session, [{ id: "inbox" }]),
      /Email\/query.*inbox.*serverFail.*Query failed/
    )
  })
})
