defmodule Fastmail.Jmap.Requests.GetEventSourceTest do
  alias Fastmail.Jmap.Requests.GetEventSource
  use ExUnit.Case, async: true

  describe "null with function" do
    test "returns a request that streams events from a function" do
      test = self()

      listener =
        Task.async(fn ->
          events = fn ->
            receive do
              {:send, event} -> event
            end
          end

          request = GetEventSource.null(events)

          {:ok, response} = Req.request(request)

          Enum.each(response.body, fn event ->
            send(test, {:event, event})
          end)
        end)

      task_pid = listener.pid
      send(task_pid, {:send, "first message"})
      assert_receive {:event, "first message"}

      send(task_pid, {:send, "second message"})
      assert_receive {:event, "second message"}
    end
  end
end
