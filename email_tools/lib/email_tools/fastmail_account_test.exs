defmodule FastmailAccountTest do
  use ExUnit.Case, async: true
  alias EmailTools.FastmailAccount

  describe "getting new email details" do
    test "updates the emails_by_mailbox mapping" do
      state = %{
        user_id: 1,
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

      result = %{
        "list" => [
          %{
            "id" => "some-email-id",
            "mailboxIds" => %{"some-mailbox-id" => true}
          }
        ]
      }

      {:noreply, new_state} = FastmailAccount.handle_info(["Email/get", result, "a"], state)

      assert new_state.emails_by_mailbox == %{
               "inbox-id" => [],
               "some-mailbox-id" => ["some-email-id"]
             }
    end

    @tag skip: "TODO"
    test("emits a message that the email has moved")
  end
end
