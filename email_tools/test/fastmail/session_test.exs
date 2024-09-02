defmodule Fastmail.SessionTest do
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

      session = Fastmail.Session.parse(data)
      assert session.account_id == "an-account-id"
      assert session.event_source_url == "https://myserver.com/events"
      assert session.api_url == "https://myserver.com/api"
    end
  end
end
