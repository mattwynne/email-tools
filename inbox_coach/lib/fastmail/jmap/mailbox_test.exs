defmodule Fastmail.Jmap.MailboxTest do
  import ExUnit.CaptureLog
  alias Fastmail.Jmap.Mailbox
  use ExUnit.Case, async: true

  describe "merge/2" do
    test "replaces old mailbox with updated mailbox" do
      old_mailbox = %Mailbox{id: "inbox", name: "Inbox", role: :inbox}
      updated_mailbox = %Mailbox{id: "inbox", name: "Inbox Updated", role: :inbox}

      result = Mailbox.merge(old_mailbox, updated_mailbox)

      assert result == %Mailbox{id: "inbox", name: "Inbox Updated", role: :inbox}
    end
  end

  describe "from_jmap/1" do
    test "converts JMAP map with inbox role" do
      jmap_data = %{
        "id" => "P-F",
        "name" => "Inbox",
        "role" => "inbox"
      }

      result = Mailbox.from_jmap(jmap_data)

      assert result == %Mailbox{id: "P-F", name: "Inbox", role: :inbox}
    end

    test "converts JMAP map with archive role" do
      jmap_data = %{
        "id" => "P1k",
        "name" => "Archive",
        "role" => "archive"
      }

      result = Mailbox.from_jmap(jmap_data)

      assert result == %Mailbox{id: "P1k", name: "Archive", role: :archive}
    end

    test "converts JMAP map with all known roles" do
      roles = [
        {"inbox", :inbox},
        {"archive", :archive},
        {"drafts", :drafts},
        {"sent", :sent},
        {"junk", :junk},
        {"trash", :trash}
      ]

      for {jmap_role, expected_atom} <- roles do
        jmap_data = %{"id" => "test-id", "name" => "Test", "role" => jmap_role}
        result = Mailbox.from_jmap(jmap_data)
        assert result.role == expected_atom
      end
    end

    test "converts JMAP map with nil role to :none" do
      jmap_data = %{
        "id" => "P2F",
        "name" => "TestFolder",
        "role" => nil
      }

      result = Mailbox.from_jmap(jmap_data)

      assert result == %Mailbox{id: "P2F", name: "TestFolder", role: :none}
    end

    test "converts JMAP map with unknown role to :none and logs warning" do
      jmap_data = %{
        "id" => "custom-1",
        "name" => "Custom Folder",
        "role" => "unknown_custom_role"
      }

      log =
        capture_log(fn ->
          result = Mailbox.from_jmap(jmap_data)
          assert result == %Mailbox{id: "custom-1", name: "Custom Folder", role: :none}
        end)

      assert log =~ "Unknown mailbox role encountered: \"unknown_custom_role\""
    end
  end
end
