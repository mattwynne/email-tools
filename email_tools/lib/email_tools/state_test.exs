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

  describe "getting details of a mailbox" do
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
