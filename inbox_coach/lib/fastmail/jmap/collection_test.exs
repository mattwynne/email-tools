defmodule Fastmail.Jmap.CollectionTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Collection
  alias Fastmail.Jmap.Mailbox

  describe "Enumerable protocol" do
    setup do
      collection =
        Collection.new("test-state-123", [
          %Mailbox{id: "inbox-id", name: "Inbox"},
          %Mailbox{id: "sent-id", name: "Sent"},
          %Mailbox{id: "drafts-id", name: "Drafts"}
        ])

      %{collection: collection}
    end

    test "has a state property", %{collection: collection} do
      assert collection.state == "test-state-123"
    end

    test "can enumerate with Enum.map", %{collection: collection} do
      names = Enum.map(collection, & &1.name)
      assert names == ["Inbox", "Sent", "Drafts"]
    end

    test "supports Enum.count", %{collection: collection} do
      assert Enum.count(collection) == 3
    end

    test "supports Enum.member?", %{collection: collection} do
      inbox = %Mailbox{id: "inbox-id", name: "Inbox"}
      other = %Mailbox{id: "other-id", name: "Other"}

      assert Enum.member?(collection, inbox) == true
      assert Enum.member?(collection, other) == false
    end

    test "supports Enum.slice", %{collection: collection} do
      result = Enum.slice(collection, 1, 2)

      assert result == [
               %Mailbox{id: "sent-id", name: "Sent"},
               %Mailbox{id: "drafts-id", name: "Drafts"}
             ]
    end

    test "supports Enum.slice with range", %{collection: collection} do
      result = Enum.slice(collection, 0..1)

      assert result == [
               %Mailbox{id: "inbox-id", name: "Inbox"},
               %Mailbox{id: "sent-id", name: "Sent"}
             ]
    end

    test "supports Enum.each", %{collection: collection} do
      test_pid = self()

      Enum.each(collection, fn mailbox ->
        send(test_pid, {:mailbox, mailbox.name})
      end)

      assert_received {:mailbox, "Inbox"}
      assert_received {:mailbox, "Sent"}
      assert_received {:mailbox, "Drafts"}
    end

    test "supports Enum.reduce", %{collection: collection} do
      result =
        Enum.reduce(collection, [], fn mailbox, acc ->
          [mailbox.name | acc]
        end)

      assert result == ["Drafts", "Sent", "Inbox"]
    end

    test "supports early termination with Enum.find", %{collection: collection} do
      result = Enum.find(collection, fn mailbox -> mailbox.id == "sent-id" end)
      assert result == %Mailbox{id: "sent-id", name: "Sent"}
    end
  end
end
