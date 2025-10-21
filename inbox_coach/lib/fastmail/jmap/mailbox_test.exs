defmodule Fastmail.Jmap.MailboxTest do
  alias Fastmail.Jmap.Mailbox
  use ExUnit.Case, async: true

  describe "merge/2" do
    test "replaces old mailbox with updated mailbox" do
      old_mailbox = %Mailbox{id: "inbox", name: "Inbox"}
      updated_mailbox = %Mailbox{id: "inbox", name: "Inbox Updated"}

      result = Mailbox.merge(old_mailbox, updated_mailbox)

      assert result == %Mailbox{id: "inbox", name: "Inbox Updated"}
    end
  end
end
