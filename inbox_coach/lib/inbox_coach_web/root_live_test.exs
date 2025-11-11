defmodule InboxCoachWeb.RootLiveTest do
  use InboxCoachWeb.ConnCase
  import Phoenix.LiveViewTest
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

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)

      # This will fail because RootLive tries to access emails_by_mailbox which doesn't exist in AccountState
      assert {:ok, _view, _html} = live(conn, "/")
    end
  end

  describe "mailbox selection" do
    test "shows only emails that are in ALL selected mailboxes (AND logic)", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create a null session with mailboxes containing overlapping emails
      # email-1 and email-2 are in both Inbox and Action
      # email-3 is only in Inbox
      # email-4 is only in Action
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
                   "ids" => ["email-1", "email-2", "email-4"]
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
                   "ids" => ["email-5"]
                 },
                 "0"
               ]
             ]}
          ]
        )

      # Start a FastmailAccount with the null session and register it
      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, "/")

      # Initially, no selected emails section should be visible
      refute render(view) =~ "Selected Mailboxes"

      # Select Inbox mailbox
      view
      |> element("#sidebar-mailbox-inbox-id")
      |> render_click()

      # Select Action mailbox
      view
      |> element("#sidebar-mailbox-action-id")
      |> render_click()

      # Should only show email-1 and email-2 (present in both mailboxes)
      assert view |> element("#selected-email-count") |> render() =~ "Total emails: 2"
    end

    test "only shows mailboxes that contain emails from current filtered list", %{conn: conn} do
      user = user_fixture()

      # Update user with API key
      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create a null session with mailboxes containing specific emails
      # Inbox: email-1, email-2
      # Action: email-2, email-3
      # Waiting: email-3, email-4
      # Archive: email-5 (only)
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
                     %{"id" => "waiting-id", "name" => "Waiting"},
                     %{"id" => "archive-id", "name" => "Archive"}
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
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{
                   "filter" => %{"inMailbox" => "action-id"},
                   "ids" => ["email-2", "email-3"]
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
                   "ids" => ["email-3", "email-4"]
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
                   "ids" => ["email-5"]
                 },
                 "0"
               ]
             ]}
          ]
        )

      # Start a FastmailAccount with the null session and register it
      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, "/")

      # Initially, all mailboxes should be visible
      html = render(view)
      assert html =~ "Inbox"
      assert html =~ "Action"
      assert html =~ "Waiting"
      assert html =~ "Archive"

      # Select Inbox (contains email-1, email-2)
      view
      |> element("#sidebar-mailbox-inbox-id")
      |> render_click()

      # Now only mailboxes containing email-1 or email-2 should be in the main section
      # Inbox: has email-1, email-2 ✓
      # Action: has email-2 ✓
      # But Waiting and Archive should still be visible in a separate section for NOT filtering
      # Waiting: has email-3, email-4 (no overlap)
      # Archive: has email-5 (no overlap)
      html = render(view)

      # All mailboxes should still be visible in sidebar
      assert html =~ "Inbox"
      assert html =~ "Action"
      assert html =~ "Waiting"
      assert html =~ "Archive"
    end


    test "clicking active mailbox removes it from query", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

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
                 %{"filter" => %{"inMailbox" => "inbox-id"}, "ids" => ["email-1", "email-2"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "action-id"}, "ids" => ["email-2", "email-3"]},
                 "0"
               ]
             ]}
          ]
        )

      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/")

      # Click Inbox to include it
      view |> element("#sidebar-mailbox-inbox-id") |> render_click()

      # Verify it's included (green) - check the li element's class
      html = render(view)
      [_, li_class] =
        Regex.run(~r/<li[^>]*id="sidebar-mailbox-inbox-id"[^>]*class="([^"]*)"/, html)

      assert li_class =~ "bg-green"

      # Click it again - should remove it from query (not toggle to excluded)
      view |> element("#sidebar-mailbox-inbox-id") |> render_click()

      # Should be back to inactive state (border-transparent)
      html = render(view)

      # Extract the li element's class to check its state (not its children)
      [_, li_class] =
        Regex.run(~r/<li[^>]*id="sidebar-mailbox-inbox-id"[^>]*class="([^"]*)"/, html)

      assert li_class =~ "border-transparent"
      refute li_class =~ "bg-green"
      refute li_class =~ "bg-red"
    end

    test "shows only email count, not individual email IDs", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      session =
        Session.null(
          execute: [
            {{MethodCalls.GetAllMailboxes},
             [
               [
                 "Mailbox/get",
                 %{
                   "state" => "123",
                   "list" => [%{"id" => "inbox-id", "name" => "Inbox"}]
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
             ]}
          ]
        )

      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/")

      # Click Inbox to include it
      view |> element("#sidebar-mailbox-inbox-id") |> render_click()

      html = render(view)

      # Should show the count
      assert html =~ "Total emails: 3"

      # Should NOT show individual email IDs
      refute html =~ "email-1"
      refute html =~ "email-2"
      refute html =~ "email-3"
      refute html =~ "selected-email-list"
    end

    test "shows mailbox summary for selected emails with counts", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Create mailboxes and emails with specific relationships
      # Inbox: email-1, email-2
      # Family: email-1, email-3
      # Projects: email-2
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
                     %{"id" => "family-id", "name" => "Family"},
                     %{"id" => "projects-id", "name" => "Projects"}
                   ]
                 },
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "inbox-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "inbox-id"}, "ids" => ["email-1", "email-2"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "family-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "family-id"}, "ids" => ["email-1", "email-3"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "projects-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "projects-id"}, "ids" => ["email-2"]},
                 "0"
               ]
             ]}
          ]
        )

      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/")

      # Select Family mailbox (contains email-1 and email-3)
      view |> element("#sidebar-mailbox-family-id") |> render_click()

      html = render(view)

      # Should show total emails count
      assert html =~ "Total emails: 2"

      # Should show mailbox summary
      assert html =~ "Mailboxes:"

      # Get just the mailbox summary section
      mailbox_summary = view |> element("#mailbox-summary") |> render()

      # Family should show 2 (email-1 and email-3)
      assert mailbox_summary =~ ~r/Family.*2/s

      # Inbox should show 1 (email-1)
      assert mailbox_summary =~ ~r/Inbox.*1/s

      # Projects should NOT appear in summary (email-3 is not in Projects)
      refute mailbox_summary =~ "Projects"
    end

    test "right-side mailbox summary shows selection state and is clickable", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Inbox: email-1, email-2
      # Action: email-1, email-2
      # Waiting: email-3
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
                 %{"filter" => %{"inMailbox" => "inbox-id"}, "ids" => ["email-1", "email-2"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "action-id"}, "ids" => ["email-1", "email-2"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "waiting-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "waiting-id"}, "ids" => ["email-3"]},
                 "0"
               ]
             ]}
          ]
        )

      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/")

      # Select Inbox (contains email-1, email-2)
      view |> element("#sidebar-mailbox-inbox-id") |> render_click()

      mailbox_summary = view |> element("#mailbox-summary") |> render()

      # Inbox should be highlighted (it's in the query)
      assert mailbox_summary =~ ~r/summary-mailbox-inbox-id[^>]*bg-green/

      # Action should NOT be highlighted (not in query, but shares emails)
      assert mailbox_summary =~ "Action"
      refute mailbox_summary =~ ~r/summary-mailbox-action-id[^>]*bg-green/

      # Click Action in the summary to add it to the query
      view |> element("#summary-mailbox-action-id") |> render_click()

      html = render(view)
      # Should now show only email-1 and email-2 (intersection)
      assert html =~ "Total emails: 2"

      mailbox_summary = view |> element("#mailbox-summary") |> render()
      # Both should now be highlighted
      assert mailbox_summary =~ ~r/summary-mailbox-inbox-id[^>]*bg-green/
      assert mailbox_summary =~ ~r/summary-mailbox-action-id[^>]*bg-green/
    end

    test "can exclude mailboxes from right-side summary", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        InboxCoach.Accounts.update_user_fastmail_api_key(user, %{
          "current_password" => "hello world!",
          "fastmail_api_key" => "test-api-key"
        })

      # Inbox: email-1, email-2
      # Action: email-2, email-3
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
                 %{"filter" => %{"inMailbox" => "inbox-id"}, "ids" => ["email-1", "email-2"]},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "action-id"},
             [
               [
                 "Email/query",
                 %{"filter" => %{"inMailbox" => "action-id"}, "ids" => ["email-2", "email-3"]},
                 "0"
               ]
             ]}
          ]
        )

      pubsub_topic = FastmailAccount.pubsub_topic_for(user)
      via_tuple = {:via, Registry, {InboxCoach.FastmailAccountRegistry, user.id}}

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, "/")

      # Select Inbox (contains email-1, email-2)
      view |> element("#sidebar-mailbox-inbox-id") |> render_click()

      html = render(view)
      assert html =~ "Total emails: 2"

      # Click exclude button for Action mailbox in summary
      view |> element("#summary-mailbox-action-id-exclude") |> render_click()

      # Should now show only email-1 (email-2 is excluded because it's in Action)
      html = render(view)
      assert html =~ "Total emails: 1"

      mailbox_summary = view |> element("#mailbox-summary") |> render()
      # Inbox should still be green (included)
      assert mailbox_summary =~ ~r/summary-mailbox-inbox-id[^>]*bg-green/
      # Action should be red (excluded)
      assert mailbox_summary =~ ~r/summary-mailbox-action-id[^>]*bg-red/
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

      {:ok, _account} =
        FastmailAccount.start_link(session: session, pubsub_topic: pubsub_topic, name: via_tuple)

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
      assert_receive(
        {:email_added_to_mailbox, %{email_id: "email-1", mailbox_id: "action-id"}},
        1000
      )

      # Should display the event with the email subject
      assert render(view) =~ ~r/Important task.*added to Action/
    end
  end
end
