defmodule FastmailAccountTest do
  use ExUnit.Case, async: true
  alias EmailTools.State
  alias EmailTools.FastmailAccount
  alias Fastmail.Jmap.Session

  describe "null mode" do
    test "connects and fetches initial state" do
      mailbox_response =
        Fastmail.Jmap.Requests.MethodCalls.null(
          Req.Response.new(
            status: 200,
            body: %{
              "methodResponses" => [
                [
                  "Mailbox/get",
                  %{
                    "list" => [
                      %{"id" => "inbox-id", "name" => "Inbox"},
                      %{"id" => "sent-id", "name" => "Sent"}
                    ]
                  },
                  "c1"
                ]
              ]
            }
          )
        )

      session = Session.null(method_calls: mailbox_response)

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
end
