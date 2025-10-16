defmodule Fastmail.Jmap.ThreadsTest do
  use ExUnit.Case
  alias Fastmail.Jmap.Threads
  alias Fastmail.Jmap.Thread

  test "can be enumerated with map" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1", "email-2"]},
      %Thread{id: "thread-2", email_ids: ["email-3"]}
    ])

    ids = Enum.map(threads, fn thread -> thread.id end)
    assert ids == ["thread-1", "thread-2"]
  end

  test "can be enumerated with filter" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1", "email-2"]},
      %Thread{id: "thread-2", email_ids: ["email-3"]}
    ])

    filtered = Enum.filter(threads, fn thread -> length(thread.email_ids) > 1 end)
    assert length(filtered) == 1
    assert hd(filtered).id == "thread-1"
  end

  test "can be counted" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1"]},
      %Thread{id: "thread-2", email_ids: ["email-2"]},
      %Thread{id: "thread-3", email_ids: ["email-3"]}
    ])

    assert Enum.count(threads) == 3
  end

  test "can check membership" do
    thread1 = %Thread{id: "thread-1", email_ids: ["email-1"]}
    thread2 = %Thread{id: "thread-2", email_ids: ["email-2"]}
    thread3 = %Thread{id: "thread-3", email_ids: ["email-3"]}

    threads = Threads.new("state-123", [thread1, thread2])

    assert Enum.member?(threads, thread1)
    assert Enum.member?(threads, thread2)
    refute Enum.member?(threads, thread3)
  end

  test "can be sliced" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1"]},
      %Thread{id: "thread-2", email_ids: ["email-2"]},
      %Thread{id: "thread-3", email_ids: ["email-3"]},
      %Thread{id: "thread-4", email_ids: ["email-4"]}
    ])

    sliced = Enum.slice(threads, 1, 2)
    assert length(sliced) == 2
    assert Enum.at(sliced, 0).id == "thread-2"
    assert Enum.at(sliced, 1).id == "thread-3"
  end

  test "can be iterated with each" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1"]},
      %Thread{id: "thread-2", email_ids: ["email-2"]}
    ])

    test_pid = self()
    Enum.each(threads, fn thread -> send(test_pid, {:thread, thread.id}) end)

    assert_receive {:thread, "thread-1"}
    assert_receive {:thread, "thread-2"}
  end

  test "can be reduced" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1", "email-2"]},
      %Thread{id: "thread-2", email_ids: ["email-3"]},
      %Thread{id: "thread-3", email_ids: ["email-4", "email-5", "email-6"]}
    ])

    total_emails = Enum.reduce(threads, 0, fn thread, acc ->
      acc + length(thread.email_ids)
    end)

    assert total_emails == 6
  end

  test "can find elements" do
    threads = Threads.new("state-123", [
      %Thread{id: "thread-1", email_ids: ["email-1"]},
      %Thread{id: "thread-2", email_ids: ["email-2"]},
      %Thread{id: "thread-3", email_ids: ["email-3"]}
    ])

    found = Enum.find(threads, fn thread -> thread.id == "thread-2" end)
    assert found.id == "thread-2"
    assert found.email_ids == ["email-2"]
  end
end
