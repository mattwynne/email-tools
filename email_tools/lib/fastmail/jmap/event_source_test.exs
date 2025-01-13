defmodule Fastmail.Jmap.EventSourceTest do
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.Credentials
  use ExUnit.Case, async: true

  describe "event source - null mode" do
    test "it can open the stream" do
      event_source = Fastmail.Jmap.EventSource.null(events: ["message one", "message two"])
      {:ok, response} = event_source |> Fastmail.Jmap.EventSource.stream()

      messages = Enum.map(response.body, fn message -> message end)
      assert messages == ["message one", "message two"]
    end
  end

  describe "event source - connected" do
    test "it can open the stream" do
      session = Fastmail.Jmap.Session.new(Credentials.from_environment())
      event_source = Fastmail.Jmap.EventSource.new(session)
      {:ok, response} = EventSource.stream(event_source)

      ["text/event-stream; charset=utf-8"] =
        Req.Response.get_header(response, "content-type")
    end
  end
end
