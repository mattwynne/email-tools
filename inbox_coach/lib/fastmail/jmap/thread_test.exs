defmodule Fastmail.Jmap.ThreadTest do
  alias Fastmail.Jmap.Thread
  use ExUnit.Case, async: true

  describe "merge/2" do
    test "replaces old thread with updated thread" do
      old_thread = %Thread{id: "thread-1", email_ids: ["email-1"]}
      updated_thread = %Thread{id: "thread-1", email_ids: ["email-1", "email-2"]}

      result = Thread.merge(old_thread, updated_thread)

      assert result == %Thread{id: "thread-1", email_ids: ["email-1", "email-2"]}
    end
  end
end
