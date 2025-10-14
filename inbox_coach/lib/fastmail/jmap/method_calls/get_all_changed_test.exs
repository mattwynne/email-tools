defmodule Fastmail.Jmap.MethodCalls.GetAllChangedTest do
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Session
  use ExUnit.Case, async: false

  @tag :online
  test "fetches latest email changes (with no since_state)" do
    Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
    |> Session.new()
    |> Session.execute(GetAllChanged, type: "Email", since_state: "J7100")
    |> dbg()
  end

  test "models the response when an email was updated" do
    Session.null(
      execute: [
        {{GetAllChanged, type: "Email", since_state: "J7100"},
         [
           [
             "Email/changes",
             %{
               "accountId" => "u4d014069",
               "created" => [],
               "destroyed" => [],
               "hasMoreChanges" => false,
               "newState" => "J7138",
               "oldState" => "J7100",
               "updated" => ["Su4vMyni5WCk"]
             },
             "changes"
           ],
           [
             "Email/get",
             %{
               "accountId" => "u4d014069",
               "list" => [
                 %{
                   "attachments" => [],
                   "bcc" => nil,
                   "blobId" => "G1ba9881e530e3410968a1a9be7332ff7092b02b3",
                   "bodyValues" => %{},
                   "cc" => nil,
                   "from" => [%{"email" => "someone@example.com", "name" => nil}],
                   "hasAttachment" => false,
                   "htmlBody" => [
                     %{
                       "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
                       "charset" => "us-ascii",
                       "cid" => nil,
                       "disposition" => nil,
                       "language" => nil,
                       "location" => nil,
                       "name" => nil,
                       "partId" => "1",
                       "size" => 0,
                       "type" => "text/plain"
                     }
                   ],
                   "id" => "Su4vMyni5WCk",
                   "inReplyTo" => nil,
                   "keywords" => %{"$seen" => true, "$x-me-annot-2" => true},
                   "mailboxIds" => %{"P2F" => true},
                   "messageId" => ["99b181e7-9ee6-1a24-5cc8-4b4bf5e4d6a0@example.com"],
                   "preview" => "",
                   "receivedAt" => "2023-12-16T00:22:15Z",
                   "references" => nil,
                   "replyTo" => nil,
                   "sender" => nil,
                   "sentAt" => "2023-12-16T00:22:13Z",
                   "size" => 9075,
                   "subject" => "A subject",
                   "textBody" => [
                     %{
                       "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
                       "charset" => "us-ascii",
                       "cid" => nil,
                       "disposition" => nil,
                       "language" => nil,
                       "location" => nil,
                       "name" => nil,
                       "partId" => "1",
                       "size" => 0,
                       "type" => "text/plain"
                     }
                   ],
                   "threadId" => "AX_dGzpWbEk7",
                   "to" => [%{"email" => "test@levain.codes", "name" => nil}]
                 }
               ],
               "notFound" => [],
               "state" => "J7138"
             },
             "get"
           ]
         ]}
      ]
    )
    |> Session.execute(GetAllChanged, type: "Email", since_state: "J7100")

    # TODO: make this method call composable - break out each of the others into their own method call, and test them independently, with their own responses.
    # then, this one can have properties for each response and simply include it.

    # TODO: assertion goes here
  end
end
