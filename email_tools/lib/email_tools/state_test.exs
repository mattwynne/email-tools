defmodule StateTest do
  alias EmailTools.Mailbox
  alias EmailTools.State
  use ExUnit.Case, async: true

  describe "getting the mailboxes that an email is currently in" do
    test "it returns the relevant mailbox_ids" do
      state = %State{
        emails_by_mailbox: %{
          "inbox-id" => ["some-email-id"],
          "some-mailbox-id" => []
        }
      }

      assert state |> State.mailbox_ids_for("some-email-id") == ["inbox-id"]
    end
  end

  describe "removing an email from a mailbox" do
    test "removes an email that's in a single mailbox" do
      state = %State{
        emails_by_mailbox: %{
          "inbox-id" => ["some-email-id"],
          "some-mailbox-id" => []
        }
      }

      assert state |> State.remove_from_mailbox("inbox-id", "some-email-id") == %State{
               emails_by_mailbox: %{
                 "inbox-id" => [],
                 "some-mailbox-id" => []
               }
             }
    end

    test "removes an email that's in a multiple mailboxes" do
      state = %State{
        emails_by_mailbox: %{
          "inbox-id" => ["some-email-id", "another-email-id"],
          "some-mailbox-id" => ["some-email-id"]
        }
      }

      assert state |> State.remove_from_mailbox("inbox-id", "some-email-id") == %State{
               emails_by_mailbox: %{
                 "inbox-id" => ["another-email-id"],
                 "some-mailbox-id" => ["some-email-id"]
               }
             }
    end
  end

  describe "adding an email to a mailbox" do
    test "it adds an email to an empty mailbox" do
      state = %State{
        emails_by_mailbox: %{
          "inbox-id" => [],
          "some-mailbox-id" => []
        }
      }

      assert state |> State.add_to_mailbox("inbox-id", "some-email-id") == %State{
               emails_by_mailbox: %{
                 "inbox-id" => ["some-email-id"],
                 "some-mailbox-id" => []
               }
             }
    end
  end

  describe "merging mailboxes" do
    test "merges existing mailboxes with incoming mailboxes based on id" do
      state = %State{
        mailboxes: %{
          "accountId" => "u4d014069",
          "list" => [
            %{
              "id" => "inbox-id",
              "name" => "Inbox"
            }
          ]
        }
      }

      new_mailboxes = %{
        "accountId" => "u4d014069",
        "list" => [
          %{
            "id" => "sent-id",
            "name" => "Sent"
          }
        ]
      }

      result = State.with_mailboxes(state, new_mailboxes)

      # Should contain both mailboxes since they have different ids
      assert length(result.mailboxes["list"]) == 2
      assert Enum.any?(result.mailboxes["list"], &(&1["id"] == "inbox-id"))
      assert Enum.any?(result.mailboxes["list"], &(&1["id"] == "sent-id"))
    end

    test "replaces existing mailbox when incoming mailbox has same id" do
      state = %State{
        mailboxes: %{
          "accountId" => "u4d014069",
          "list" => [
            %{
              "id" => "inbox-id",
              "name" => "Inbox",
              "old_field" => "old_value"
            }
          ]
        }
      }

      new_mailboxes = %{
        "accountId" => "u4d014069",
        "list" => [
          %{
            "id" => "inbox-id",
            "name" => "Updated Inbox",
            "new_field" => "new_value"
          }
        ]
      }

      result = State.with_mailboxes(state, new_mailboxes)

      # Should have only one mailbox with the updated data
      assert length(result.mailboxes["list"]) == 1
      inbox = Enum.find(result.mailboxes["list"], &(&1["id"] == "inbox-id"))
      assert inbox["name"] == "Updated Inbox"
      assert inbox["new_field"] == "new_value"
      refute Map.has_key?(inbox, "old_field")
    end

    test "handles empty existing mailboxes" do
      state = %State{
        mailboxes: %{}
      }

      new_mailboxes = %{
        "accountId" => "u4d014069",
        "list" => [
          %{
            "id" => "inbox-id",
            "name" => "Inbox"
          }
        ]
      }

      result = State.with_mailboxes(state, new_mailboxes)

      assert result.mailboxes["list"] == [
               %{
                 "id" => "inbox-id",
                 "name" => "Inbox"
               }
             ]
    end

    test "handles empty incoming mailboxes" do
      state = %State{
        mailboxes: %{
          "accountId" => "u4d014069",
          "list" => [
            %{
              "id" => "inbox-id",
              "name" => "Inbox"
            }
          ]
        }
      }

      new_mailboxes = %{
        "accountId" => "u4d014069",
        "list" => []
      }

      result = State.with_mailboxes(state, new_mailboxes)

      assert result.mailboxes["list"] == [
               %{
                 "id" => "inbox-id",
                 "name" => "Inbox"
               }
             ]
    end

    test "handles mixed scenario with duplicates and new mailboxes" do
      state = %State{
        mailboxes: %{
          "accountId" => "u4d014069",
          "list" => [
            %{
              "id" => "inbox-id",
              "name" => "Old Inbox"
            },
            %{
              "id" => "drafts-id",
              "name" => "Drafts"
            }
          ]
        }
      }

      new_mailboxes = %{
        "accountId" => "u4d014069",
        "list" => [
          %{
            "id" => "inbox-id",
            "name" => "Updated Inbox"
          },
          %{
            "id" => "sent-id",
            "name" => "Sent"
          }
        ]
      }

      result = State.with_mailboxes(state, new_mailboxes)

      # Should have 3 mailboxes: updated inbox, drafts, and new sent
      assert length(result.mailboxes["list"]) == 3

      inbox = Enum.find(result.mailboxes["list"], &(&1["id"] == "inbox-id"))
      assert inbox["name"] == "Updated Inbox"

      drafts = Enum.find(result.mailboxes["list"], &(&1["id"] == "drafts-id"))
      assert drafts["name"] == "Drafts"

      sent = Enum.find(result.mailboxes["list"], &(&1["id"] == "sent-id"))
      assert sent["name"] == "Sent"
    end
  end

  describe "getting details of a mailbox" do
    test "finds mailbox by id" do
      state = %State{
        mailboxes: %{
          "accountId" => "u4d014069",
          "list" => [
            %{
              "id" => "7a02d2a5-15c5-4fd5-99f7-1e3b511a991c",
              "name" => "Inbox"
            }
          ]
        }
      }

      assert state
             |> State.mailbox("7a02d2a5-15c5-4fd5-99f7-1e3b511a991c")
             |> Mailbox.name() ==
               "Inbox"
    end
  end
end
