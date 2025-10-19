defmodule Fastmail.Jmap.Requests.GetEventSourceTest do
  alias Fastmail.Jmap.Requests.GetEventSource
  use ExUnit.Case, async: true

  describe "null with function" do
    test "returns a request that streams events from a function" do
      test = self()

      Task.async(fn ->
        {:ok, response} =
          Req.request(
            GetEventSource.null(fn ->
              receive do
                {:emit, event} -> event
              end
            end)
          )

        send(test, {:ready, self()})

        Enum.each(response.body, fn event ->
          send(test, {:event, event})
        end)
      end)

      assert_receive {:ready, stub}

      send(stub, {:emit, "first message"})
      assert_receive {:event, "first message"}

      send(stub, {:emit, "second message"})
      assert_receive {:event, "second message"}
    end
  end
end
