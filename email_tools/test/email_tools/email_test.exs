defmodule EmailTest do
  use ExUnit.Case, async: true
  alias EmailTools.Email

  describe "an email" do
    test "id/1" do
      email = %{
        "id" => "some-email-id"
      }

      assert email |> Email.id() == "some-email-id"
    end

    test "mailbox_ids/1" do
      email = %{
        "mailboxIds" => %{"some-mailbox-id" => true}
      }

      assert email |> Email.mailbox_ids() == ["some-mailbox-id"]
    end
  end
end
