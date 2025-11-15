defmodule Fastmail.Jmap.CollectionTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Email
  alias Fastmail.Jmap.Contact
  alias Fastmail.Jmap.Collection
  alias Fastmail.Jmap.Mailbox

  describe "merging in another collection" do
    test "returns a collection with the new collections's state" do
      alias Fastmail.Jmap.Email
      alias Fastmail.Jmap.Contact

      existing =
        Collection.new("123", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      updated =
        Collection.new("456", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox", "action"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      result = Collection.update(existing, updated)

      assert result.state == "456"
    end

    test "updates any existing emails with properties from the updated collection" do
      alias Fastmail.Jmap.Email
      alias Fastmail.Jmap.Contact

      existing =
        Collection.new("123", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      updated =
        Collection.new("456", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox", "action"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      result = Collection.update(existing, updated)

      assert result.list == [
               %Email{
                 id: "email-1",
                 mailbox_ids: ["inbox", "action"],
                 from: [%Contact{email: "a@b.com"}],
                 thread_id: "a-thread"
               }
             ]
    end

    test "leaves existing emails alone" do
      alias Fastmail.Jmap.Email
      alias Fastmail.Jmap.Contact

      existing =
        Collection.new("123", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          },
          %Email{
            id: "email-2",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "x@y.com"}],
            thread_id: "a-thread"
          }
        ])

      updated =
        Collection.new("456", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox", "action"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      result = Collection.update(existing, updated)

      assert result.list == [
               %Email{
                 id: "email-1",
                 mailbox_ids: ["inbox", "action"],
                 from: [%Contact{email: "a@b.com"}],
                 thread_id: "a-thread"
               },
               %Email{
                 id: "email-2",
                 mailbox_ids: ["inbox"],
                 from: [%Contact{email: "x@y.com"}],
                 thread_id: "a-thread"
               }
             ]
    end

    test "adds new items from the updated collection" do
      alias Fastmail.Jmap.Email
      alias Fastmail.Jmap.Contact

      existing =
        Collection.new("123", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      updated =
        Collection.new("456", [
          %Email{
            id: "email-2",
            mailbox_ids: ["inbox"],
            from: [%Contact{email: "x@y.com"}],
            thread_id: "b-thread"
          }
        ])

      result = Collection.update(existing, updated)

      assert result.list == [
               %Email{
                 id: "email-1",
                 mailbox_ids: ["inbox"],
                 from: [%Contact{email: "a@b.com"}],
                 thread_id: "a-thread"
               },
               %Email{
                 id: "email-2",
                 mailbox_ids: ["inbox"],
                 from: [%Contact{email: "x@y.com"}],
                 thread_id: "b-thread"
               }
             ]
    end

    test "works on an empty existing collection" do
      # TODO: consider using a null object for Collection
      existing = nil

      updated =
        Collection.new("456", [
          %Email{
            id: "email-1",
            mailbox_ids: ["inbox", "action"],
            from: [%Contact{email: "a@b.com"}],
            thread_id: "a-thread"
          }
        ])

      result = Collection.update(existing, updated)

      assert result.list == [
               %Email{
                 id: "email-1",
                 mailbox_ids: ["inbox", "action"],
                 from: [%Contact{email: "a@b.com"}],
                 thread_id: "a-thread"
               }
             ]
    end
  end

  describe "get/2" do
    test "returns the item with the matching ID" do
      collection =
        Collection.new("test-state", [
          %Mailbox{id: "inbox-id", name: "Inbox"},
          %Mailbox{id: "sent-id", name: "Sent"}
        ])

      result = Collection.get(collection, "sent-id")

      assert result == %Mailbox{id: "sent-id", name: "Sent"}
    end

    test "returns nil when ID not found" do
      collection =
        Collection.new("test-state", [
          %Mailbox{id: "inbox-id", name: "Inbox"}
        ])

      result = Collection.get(collection, "nonexistent-id")

      assert result == nil
    end

    test "returns nil for empty collection" do
      collection = Collection.new("test-state", [])

      result = Collection.get(collection, "any-id")

      assert result == nil
    end
  end

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
