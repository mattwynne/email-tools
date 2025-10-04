defmodule FastmailAccountTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.MethodCalls
  alias InboxCoach.State
  alias InboxCoach.FastmailAccount
  alias Fastmail.Jmap.Session

  describe "null mode" do
    test "connects and fetches initial state" do
      session =
        Session.null(
          execute: [
            {{MethodCalls.GetAllMailboxes},
             [
               "Mailbox/get",
               %{
                 "list" => [
                   %{"id" => "inbox-id", "name" => "Inbox"},
                   %{"id" => "sent-id", "name" => "Sent"}
                 ]
               },
               "0"
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "inbox-id"},
             [
               "Email/query",
               %{},
               "0"
             ]},
            {{MethodCalls.QueryAllEmails, in_mailbox: "sent-id"},
             [
               "Email/query",
               %{},
               "0"
             ]}
          ]
        )

      {:ok, account} = FastmailAccount.start_link(session: session, pubsub_topic: "test")

      state = FastmailAccount.get_state(account)

      mailbox_list = state.mailboxes["list"]
      assert length(mailbox_list) == 2
      assert Enum.find(mailbox_list, &(&1["name"] == "Inbox"))
      assert Enum.find(mailbox_list, &(&1["name"] == "Sent"))
    end
  end

  describe "getting new email details" do
    test "updates the emails_by_mailbox mapping" do
      state = %{
        pubsub_topic: "fastmail-account:1",
        account_state: %State{
          mailboxes: %{
            "list" => [
              %{"id" => "inbox-id", "name" => "Inbox"},
              %{"id" => "some-mailbox-id", "name" => "Some mailbox"}
            ]
          },
          emails_by_mailbox: %{
            "inbox-id" => ["some-email-id"],
            "some-mailbox-id" => []
          }
        }
      }

      result = %{
        "list" => [
          %{
            "id" => "some-email-id",
            "mailboxIds" => %{"some-mailbox-id" => true}
          }
        ]
      }

      {:noreply, new_state} = FastmailAccount.handle_info(["Email/get", result, "a"], state)

      assert new_state.account_state.emails_by_mailbox == %{
               "inbox-id" => [],
               "some-mailbox-id" => ["some-email-id"]
             }
    end

    @tag skip: "TODO"
    test("emits a message that the email has moved")
  end

  test "handling events" do
    test = self()

    # fake event source request body - function that returns events
    events_stub = fn ->
      send(test, {:ready, self()})

      # TODO: loop for more than one event
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
             "Mailbox/get",
             %{
               "list" => [
                 %{"id" => "inbox-id", "name" => "Inbox"},
                 %{"id" => "sent-id", "name" => "Sent"}
               ]
             },
             "0"
           ]},
          {{MethodCalls.QueryAllEmails, in_mailbox: "inbox-id"},
           [
             "Email/query",
             %{
               "filter" => %{"inMailbox" => "inbox-id"},
               "ids" => ["email-1"]
             },
             "0"
           ]},
          {{MethodCalls.QueryAllEmails, in_mailbox: "sent-id"},
           [
             "Email/query",
             %{
               "filter" => %{"inMailbox" => "sent-id"},
               "ids" => ["email-2"]
             },
             "0"
           ]},
          {{MethodCalls.GetAllChanged, type: "Email", since_state: "state-1"},
           [
             "Email/changes",
             %{
               "updated" => ["email-1"]
             },
             "0"
           ]},
          {{MethodCalls.GetAllChanged, type: "Mailbox", since_state: "state-1"},
           [
             "Mailbox/changes",
             %{},
             "0"
           ]},
          {{MethodCalls.GetAllChanged, type: "Thread", since_state: "state-1"},
           [
             "Thread/changes",
             %{},
             "0"
           ]},
          {{MethodCalls.GetEmailsByIds, ids: ["email-1"]},
           [
             "Email/get",
             %{
               "list" => [
                 %{"id" => "email-1", "mailboxIds" => %{"sent-id" => true}}
               ]
             },
             "0"
           ]}
        ]
      )

    Phoenix.PubSub.subscribe(
      InboxCoach.PubSub,
      "test"
    )

    {:ok, _account} = FastmailAccount.start_link(session: session, pubsub_topic: "test")

    assert_receive({:ready, events})

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

    assert_receive({:state, %InboxCoach.State{emails_by_mailbox: %{}, mailboxes: %{}}})

    assert_receive(
      {:state,
       %InboxCoach.State{
         emails_by_mailbox: %{},
         mailboxes: %{
           "list" => [
             %{"id" => "inbox-id", "name" => "Inbox"},
             %{"id" => "sent-id", "name" => "Sent"}
           ]
         }
       }}
    )

    assert_receive(
      {:state,
       %InboxCoach.State{
         emails_by_mailbox: %{
           "inbox-id" => ["email-1"]
         },
         mailboxes: %{
           "list" => [
             %{"id" => "inbox-id", "name" => "Inbox"},
             %{"id" => "sent-id", "name" => "Sent"}
           ]
         }
       }}
    )

    assert_receive(
      {:state,
       %InboxCoach.State{
         emails_by_mailbox: %{
           "inbox-id" => ["email-1"],
           "sent-id" => ["email-2"]
         },
         mailboxes: %{
           "list" => [
             %{"id" => "inbox-id", "name" => "Inbox"},
             %{"id" => "sent-id", "name" => "Sent"}
           ]
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

    assert_receive(
      {:state,
       %InboxCoach.State{
         emails_by_mailbox: %{
           "inbox-id" => [],
           "sent-id" => ["email-2", "email-1"]
         },
         mailboxes: %{
           "list" => [
             %{"id" => "inbox-id", "name" => "Inbox"},
             %{"id" => "sent-id", "name" => "Sent"}
           ]
         }
       }}
    )
  end
end
