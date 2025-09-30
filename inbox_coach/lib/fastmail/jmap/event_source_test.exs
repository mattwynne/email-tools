defmodule Fastmail.Jmap.EventSourceTest do
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.Credentials
  use ExUnit.Case, async: true

  describe "event source - null mode" do
    test "it can open the stream with explicit events" do
      event_source = Fastmail.Jmap.EventSource.null(events: ["message one", "message two"])
      {:ok, response} = event_source |> Fastmail.Jmap.EventSource.stream()

      messages = Enum.map(response.body, fn message -> message end)
      assert messages == ["message one", "message two"]
    end

    test "it defaults to empty events when called without parameters" do
      event_source = Fastmail.Jmap.EventSource.null()
      {:ok, response} = event_source |> Fastmail.Jmap.EventSource.stream()

      messages = Enum.map(response.body, fn message -> message end)
      assert messages == []
    end

    test "it can receive events sent at will during the test" do
      test = self()

      listener =
        Task.async(fn ->
          events = fn ->
            receive do
              {:send, event} -> event
            end
          end

          event_source = EventSource.null(events: events)
          {:ok, response} = event_source |> EventSource.stream()

          Enum.each(response.body, fn event ->
            send(test, {:event, event})
          end)
        end)

      send(listener.pid, {:send, "first message"})
      assert_receive {:event, "first message"}
    end
  end

  describe "event source - connected" do
    @tag :online
    test "it can open the stream" do
      session = Fastmail.Jmap.Session.new(Credentials.from_environment("TEST_FASTMAIL_API_TOKEN"))
      event_source = Fastmail.Jmap.EventSource.new(session)
      {:ok, response} = EventSource.stream(event_source)

      ["text/event-stream; charset=utf-8"] =
        Req.Response.get_header(response, "content-type")
    end
  end
end
