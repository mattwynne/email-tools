defmodule InboxCoachWeb.RootLiveTest do
  use InboxCoachWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Fastmail.Jmap.MethodCalls
  alias Fastmail.Jmap.Session
  alias InboxCoach.FastmailAccount
  import InboxCoach.AccountsFixtures

  describe "mount/3" do
    test "displays mailboxes with email counts from AccountState", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create a null session with stubbed responses
      session =
        Session.null(
          execute: [
            {{MethodCalls.GetAllMailboxes},
             [
               [
                 "Mailbox/get",
                 %{
                   "state" => "123",
                   "list" => [
                     %{"id" => "inbox-id", "name" => "Inbox"},
                     %{"id" => "sent-id", "name" => "Sent"}
                   ]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "inbox-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "inbox-id"},
                   "ids" => ["email-1", "email-2"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "sent-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "sent-id"},
                   "ids" => ["email-3"]
                 },
                 "0"
               ]
             ]}
          ]
        )

      # Start a FastmailAccount with the null session and register it
      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}
      {:ok, _account} = FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)

      # This will fail because RootLive tries to access emails_by_mailbox which doesn't exist in AccountState
      assert {:ok, _view, _html} = live(conn, "/")
    end
  end
end
