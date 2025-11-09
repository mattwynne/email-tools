defmodule InboxCoachWeb.RootLiveTest do
  use InboxCoachWeb.ConnCase
  import Phoenix.LiveViewTest
  import PhoenixTest
  alias Fastmail.Jmap.MethodCalls
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.AccountState
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

  describe "live email count" do
    test "displays total count of emails excluding archive and junk mailboxes", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create a null session with mailboxes having different roles
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
                     %{"id" => "inbox-id", "name" => "Inbox", "role" => "inbox"},
                     %{"id" => "archive-id", "name" => "Archive", "role" => "archive"},
                     %{"id" => "junk-id", "name" => "Junk", "role" => "junk"},
                     %{"id" => "custom-id", "name" => "Projects", "role" => nil}
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
                   "ids" => ["email-1", "email-2", "email-3"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "archive-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "archive-id"},
                   "ids" => ["email-4", "email-5"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "junk-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "junk-id"},
                   "ids" => ["email-6"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "custom-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "custom-id"},
                   "ids" => ["email-7", "email-8"]
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

      {:ok, view, _html} = live(conn, "/")

      # Should display total count of 5 (3 from Inbox + 2 from Projects, excluding 2 from Archive and 1 from Junk)
      assert view |> element("#live-email-count") |> render() =~ "5"
    end
  end

  describe "mailbox selection" do
    test "allows selecting mailboxes and displays their email_ids with count", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create a null session with mailboxes containing emails
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
                     %{"id" => "action-id", "name" => "Action"},
                     %{"id" => "waiting-id", "name" => "Waiting"}
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
                   "ids" => ["email-1", "email-2", "email-3"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "action-id"},
                   "ids" => ["email-4", "email-5"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "waiting-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "waiting-id"},
                   "ids" => ["email-6"]
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

      # Visit the page and select mailboxes using phoenix_test
      conn
      |> visit("/")
      |> refute_has("#selected-email-count")
      |> check("Inbox")
      |> check("Action")
      |> assert_has("#selected-email-count", text: "Total emails: 5")
      |> assert_has("#selected-email-list", text: "email-1")
      |> assert_has("#selected-email-list", text: "email-2")
      |> assert_has("#selected-email-list", text: "email-3")
      |> assert_has("#selected-email-list", text: "email-4")
      |> assert_has("#selected-email-list", text: "email-5")
      |> refute_has("#selected-email-list", text: "email-6")
    end
  end

  describe "stream tab" do
    test "displays email movement events in a feed", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      test_pid = self()

      # Set up events stub that waits for eventsource events
      events_stub = fn ->
        send(test_pid, {:ready, self()})

        receive do
          {:event, event} -> event
        end
      end

      # Create a null session with stubbed responses
      session =
        Session.null(
          event_source: EventSource.null(events: events_stub),
          execute: [
            {{MethodCalls.GetAllMailboxes},
             [
               [
                 "Mailbox/get",
                 %{
                   "state" => "123",
                   "list" => [
                     %{"id" => "inbox-id", "name" => "Inbox"},
                     %{"id" => "action-id", "name" => "Action"}
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
                   "ids" => ["email-1"]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "action-id"},
                   "ids" => []
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.GetAllChanged, type: "Email", since_state: "123"},
             [
               [
                 "Email/changes",
                 %{
                   "oldState" => "123",
                   "newState" => "456",
                   "updated" => ["email-1"]
                 },
                 "0"
               ],
               [
                 "Email/get",
                 %{
                   "state" => "456",
                   "list" => [
                     %{
                       "id" => "email-1",
                       "subject" => "Important task",
                       "threadId" => "thread-1",
                       "from" => [%{"email" => "test@example.com", "name" => nil}],
                       "mailboxIds" => %{"inbox-id" => true, "action-id" => true}
                     }
                   ]
                 },
                 "updated"
               ]
             ]}
          ]
        )

      # Start a FastmailAccount with the null session and register it
      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}
      {:ok, _account} = FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      # Wait for event source to be ready
      assert_receive({:ready, events})

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, "/")

      # Subscribe to PubSub to track events
      Phoenix.PubSub.subscribe(InboxCoach.PubSub, pubsub_topic)

      # Send initial connect event to establish baseline state
      send(
        events,
        {
          :event,
          %{
            "changed" => %{
              "some-account-id" => %{
                "Email" => "123",
                "Mailbox" => "123",
                "Thread" => "123"
              }
            },
            "type" => "connect"
          }
        }
      )

      # Wait for initial state to be processed
      assert_receive({:state, %AccountState{}}, 1000)

      # Now send state change event to trigger Email update
      send(
        events,
        {
          :event,
          %{
            "changed" => %{
              "some-account-id" => %{
                "Email" => "456",
                "Mailbox" => "123",
                "Thread" => "123"
              }
            },
            "type" => "StateChange"
          }
        }
      )

      # Wait for the email_added_to_mailbox event to be broadcast
      assert_receive({:email_added_to_mailbox, %{email_id: "email-1", mailbox_id: "action-id"}}, 1000)

      # Should display the event with the email subject
      assert render(view) =~ ~r/Important task.*added to Action/
    end
  end
end
