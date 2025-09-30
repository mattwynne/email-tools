defmodule FastmailAccountTest do
  use ExUnit.Case, async: true
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

    events = fn ->
      send(test, {:ready, self()})

      receive do
        {:event, message} -> message
      end
    end

    session =
      Session.null(
        event_source: EventSource.null(events: events),
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
             %{"list" => ["email-1"]},
             "0"
           ]},
          {{MethodCalls.QueryAllEmails, in_mailbox: "sent-id"},
           [
             "Email/query",
             %{"list" => ["email-2"]},
             "0"
           ]}
        ]
      )

    Phoenix.PubSub.subscribe(InboxCoach.PubSub, "test")
    {:ok, account} = FastmailAccount.start_link(session: session, pubsub_topic: "test")
    assert_receive({:state, brandNewState})
    dbg(brandNewState)
    assert_receive({:state, initialState})
    dbg(initialState)
    assert_receive({:state, state3})
    dbg(state3)

    events =
      receive do
        {:ready, events} -> events
      end

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

    assert_receive({:state, state4})
    dbg(state4)
    assert state2 = account |> FastmailAccount.get_state()
  end
end
