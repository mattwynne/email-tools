defmodule Fastmail.Jmap.MethodCalls.QueryAllEmailsTest do
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Session
  use ExUnit.Case, async: false

  @tag :online
  test "fetches email ids" do
    Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
    |> Session.new()
    |> Session.execute(QueryAllEmails, in_mailbox: "P2F")
  end

  test "models the response" do
    session =
      Session.null(
        execute: [
          {
            {QueryAllEmails, in_mailbox: "P2F"},
            [
              [
                "Email/query",
                %{
                  "accountId" => "u4d014069",
                  "canCalculateChanges" => true,
                  "collapseThreads" => false,
                  "filter" => %{"inMailbox" => "P2F"},
                  "ids" => ["Su4vMyni5WCk"],
                  "position" => 0,
                  "queryState" => "J7138:0",
                  "total" => 1
                },
                "query"
              ]
            ]
          }
        ]
      )

    response = Session.execute(session, QueryAllEmails, in_mailbox: "P2F")

    assert ^response = %QueryAllEmails.Response{
             mailbox_id: "P2F",
             email_ids: ["Su4vMyni5WCk"]
           }
  end
end
