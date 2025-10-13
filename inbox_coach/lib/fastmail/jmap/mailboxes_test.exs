defmodule Fastmail.Jmap.MailboxesTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Mailboxes
  alias Fastmail.Jmap.Mailbox

  describe "Enumerable protocol" do
    setup do
      mailboxes =
        Mailboxes.new("test-state-123", [
          %Mailbox{id: "inbox-id", name: "Inbox"},
          %Mailbox{id: "sent-id", name: "Sent"},
          %Mailbox{id: "drafts-id", name: "Drafts"}
        ])

      %{mailboxes: mailboxes}
    end

    test "has a state property", %{mailboxes: mailboxes} do
      assert mailboxes.state == "test-state-123"
    end

    test "can enumerate with Enum.map", %{mailboxes: mailboxes} do
      names = Enum.map(mailboxes, & &1.name)
      assert names == ["Inbox", "Sent", "Drafts"]
    end

    test "supports Enum.count", %{mailboxes: mailboxes} do
      assert Enum.count(mailboxes) == 3
    end

    test "supports Enum.member?", %{mailboxes: mailboxes} do
      inbox = %Mailbox{id: "inbox-id", name: "Inbox"}
      other = %Mailbox{id: "other-id", name: "Other"}

      assert Enum.member?(mailboxes, inbox) == true
      assert Enum.member?(mailboxes, other) == false
    end

    test "supports Enum.slice", %{mailboxes: mailboxes} do
      result = Enum.slice(mailboxes, 1, 2)

      assert result == [
               %Mailbox{id: "sent-id", name: "Sent"},
               %Mailbox{id: "drafts-id", name: "Drafts"}
             ]
    end

    test "supports Enum.slice with range", %{mailboxes: mailboxes} do
      result = Enum.slice(mailboxes, 0..1)

      assert result == [
               %Mailbox{id: "inbox-id", name: "Inbox"},
               %Mailbox{id: "sent-id", name: "Sent"}
             ]
    end

    test "supports Enum.each", %{mailboxes: mailboxes} do
      test_pid = self()

      Enum.each(mailboxes, fn mailbox ->
        send(test_pid, {:mailbox, mailbox.name})
      end)

      assert_received {:mailbox, "Inbox"}
      assert_received {:mailbox, "Sent"}
      assert_received {:mailbox, "Drafts"}
    end

    test "supports Enum.reduce", %{mailboxes: mailboxes} do
      result =
        Enum.reduce(mailboxes, [], fn mailbox, acc ->
          [mailbox.name | acc]
        end)

      assert result == ["Drafts", "Sent", "Inbox"]
    end

    test "supports early termination with Enum.find", %{mailboxes: mailboxes} do
      result = Enum.find(mailboxes, fn mailbox -> mailbox.id == "sent-id" end)
      assert result == %Mailbox{id: "sent-id", name: "Sent"}
    end
  end
end
