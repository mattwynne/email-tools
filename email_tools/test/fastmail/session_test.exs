defmodule Fastmail.SessionTest do
  alias Fastmail.WebService
  use ExUnit.Case, async: true

  describe "creating a new instance from a response JSON map" do
    test "it can be configured as a connected session" do
      data = %{
        "accounts" => %{
          "an-account-id" => %{}
        },
        "eventSourceUrl" => "https://myserver.com/events",
        "apiUrl" => "https://myserver.com/api"
      }

      session = Fastmail.Session.new(data, WebService.create_null())
      assert session.account_id == "an-account-id"
      assert session.api_url == "https://myserver.com/api"
    end
  end

  describe "connecting to the event source" do
    test "it can open the stream" do
      session = Fastmail.Session.create_null(events: ["message one", "message two"])
      {:ok, response} = session |> Fastmail.Session.event_stream()

      messages = Enum.map(response.body, fn message -> message end)
      assert messages == ["message one", "message two"]
    end
  end
end
