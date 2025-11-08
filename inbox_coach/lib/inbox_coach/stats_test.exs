defmodule InboxCoach.StatsTest do
  alias InboxCoach.Stats
  alias Fastmail.Jmap.AccountState
  alias Fastmail.Jmap.Collection
  alias Fastmail.Jmap.Mailbox
  use ExUnit.Case, async: true

  describe "count_emails_not_in_archive/1" do
    test "counts unique emails that are not in archive, junk, sent, or trash mailboxes" do
      archive_mailbox = %Mailbox{id: "archive-id", name: "Archive", role: :archive}
      junk_mailbox = %Mailbox{id: "junk-id", name: "Junk", role: :junk}
      sent_mailbox = %Mailbox{id: "sent-id", name: "Sent", role: :sent}
      trash_mailbox = %Mailbox{id: "trash-id", name: "Trash", role: :trash}
      inbox_mailbox = %Mailbox{id: "inbox-id", name: "Inbox", role: :inbox}

      state = %AccountState{
        mailboxes: Collection.new("state1", [inbox_mailbox, archive_mailbox, junk_mailbox, sent_mailbox, trash_mailbox]),
        mailbox_emails: %{
          "inbox-id" => ["e1", "e2"],
          "archive-id" => ["e2", "e3"],
          "junk-id" => ["e4"],
          "sent-id" => ["e5"],
          "trash-id" => ["e6"]
        }
      }

      result = Stats.count_emails_not_in_archive(state)

      assert result == 1
    end

    test "returns 0 when all emails are in archive, junk, sent, or trash" do
      archive_mailbox = %Mailbox{id: "archive-id", name: "Archive", role: :archive}
      junk_mailbox = %Mailbox{id: "junk-id", name: "Junk", role: :junk}
      sent_mailbox = %Mailbox{id: "sent-id", name: "Sent", role: :sent}
      trash_mailbox = %Mailbox{id: "trash-id", name: "Trash", role: :trash}

      state = %AccountState{
        mailboxes: Collection.new("state1", [archive_mailbox, junk_mailbox, sent_mailbox, trash_mailbox]),
        mailbox_emails: %{
          "archive-id" => ["e1", "e2"],
          "junk-id" => ["e3"],
          "sent-id" => ["e4"],
          "trash-id" => ["e5"]
        }
      }

      result = Stats.count_emails_not_in_archive(state)

      assert result == 0
    end

    test "returns total count when no excluded mailboxes exist" do
      inbox_mailbox = %Mailbox{id: "inbox-id", name: "Inbox", role: :inbox}

      state = %AccountState{
        mailboxes: Collection.new("state1", [inbox_mailbox]),
        mailbox_emails: %{
          "inbox-id" => ["e1", "e2"]
        }
      }

      result = Stats.count_emails_not_in_archive(state)

      assert result == 2
    end
  end
end
