defmodule FastmailTest do
  use ExUnit.Case, async: true

  describe "jmap - null mode" do
    test "default session returns no mailboxes" do
      # fake_requests = [
      #   FakeRequest.session(),
      #   FakeRequest.mailbox_get([])
      # ]

      # Fastmail.jmap(fake_requests)
      # |> Fastmail.Jmap.all_mailboxes()
    end
  end
end
