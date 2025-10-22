defmodule FastmailAccountTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.MethodCalls
  alias Fastmail.Jmap.AccountState
  alias Fastmail.Jmap.Mailbox
  alias InboxCoach.FastmailAccount
  alias Fastmail.Jmap.Session

  describe "null mode" do
    test "connects and fetches initial state" do
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
                 %{},
                 "0"
               ]
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "sent-id"},
             [
               [
                 "Email/query",
                 %{},
                 "0"
               ]
             ]}
          ]
        )

      {:ok, account} = FastmailAccount.start_link(session: session, pubsub_topic: "test")

      state = FastmailAccount.get_state(account)

      assert %AccountState{
               mailboxes: %{
                 list: [
                   %Mailbox{id: "inbox-id", name: "Inbox"},
                   %Mailbox{id: "sent-id", name: "Sent"}
                 ]
               }
             } = state
    end
  end

  test "handling events" do
    test = self()

    # fake event source request body - function that returns events
    events_stub = fn ->
      send(test, {:ready, self()})

      receive do
        {:event, event} -> event
      end
    end

    session =
      Session.null(
        get_session: GetSession.null(account_id: "account-id"),
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
                 "ids" => ["email-1"]
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
                 "ids" => ["email-2"]
               },
               "0"
             ]
           ]},
          {{MethodCalls.GetAllChanged, type: "Email", since_state: "state-1"},
           [
             [
               "Email/changes",
               %{
                 "newState" => "123",
                 "oldState" => "122",
                 "updated" => ["email-1"]
               },
               "0"
             ],
             [
               "Email/get",
               %{
                 "state" => "123",
                 "list" => [
                   %{
                     "id" => "email-1",
                     "from" => [%{"email" => "me@example.com"}],
                     "mailboxIds" => %{"sent-id" => true}
                   }
                 ]
               },
               "updated"
             ]
           ]},
          {{MethodCalls.GetAllChanged, type: "Mailbox", since_state: "state-1"},
           [
             [
               "Mailbox/changes",
               %{
                 "oldState" => "122",
                 "newState" => "123",
                 "updated" => ["archive-id"]
               },
               "0"
             ],
             [
               "Mailbox/get",
               %{
                 "state" => "123",
                 "list" => [
                   %{"id" => "archive-id", "name" => "Archive"}
                 ]
               },
               "updated"
             ]
           ]},
          {{MethodCalls.QueryAllEmails, in_mailbox: "archive-id"},
           [
             [
               "Email/query",
               %{
                 "filter" => %{"inMailbox" => "archive-id"},
                 "ids" => ["email-3", "email-4"]
               },
               "0"
             ]
           ]},
          {{MethodCalls.GetAllChanged, type: "Thread", since_state: "state-1"},
           [
             [
               "Thread/changes",
               %{
                 "oldState" => "state-0",
                 "newState" => "state-1"
               },
               "0"
             ],
             [
               "Thread/get",
               %{
                 "state" => "state-1",
                 "list" => []
               },
               "updated"
             ]
           ]}
        ]
      )

    Phoenix.PubSub.subscribe(
      InboxCoach.PubSub,
      "test"
    )

    {:ok, _account} = FastmailAccount.start_link(session: session, pubsub_topic: "test")

    assert_receive({:ready, events})
    assert_receive({:state, %AccountState{mailboxes: nil}})

    send(
      events,
      {
        :event,
        %{
          "changed" => %{
            "account-id" => %{
              "Email" => "state-1",
              "EmailDelivery" => "state-1",
              "Mailbox" => "state-1",
              "Thread" => "state-1"
            }
          },
          "type" => "connect"
        }
      }
    )

    assert_receive(
      {:state,
       %AccountState{
         mailbox_emails: %{
           "inbox-id" => ["email-1"]
         }
       }}
    )

    assert_receive(
      {:state,
       %AccountState{
         mailbox_emails: %{
           "inbox-id" => ["email-1"],
           "sent-id" => ["email-2"]
         }
       }}
    )

    send(
      events,
      {
        :event,
        %{
          "changed" => %{
            "account-id" => %{
              "Email" => "state-2",
              "EmailDelivery" => "state-1",
              "Mailbox" => "state-2",
              "Thread" => "state-2"
            }
          },
          "type" => "client"
        }
      }
    )

    # After mailbox changes, QueryAllEmails should be called for updated mailboxes
    assert_receive(
      {:state,
       %AccountState{
         mailbox_emails: %{
           "archive-id" => ["email-3", "email-4"]
         }
       }}
    )
  end
end
