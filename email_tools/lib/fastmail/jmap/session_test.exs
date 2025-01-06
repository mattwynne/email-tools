defmodule Fastmail.Jmap.SessionTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.Session.NullConfig

  describe "connecting" do
    test "connects when created" do
      credentials = Fastmail.Jmap.Credentials.from_environment()
      session = Fastmail.Jmap.Session.new(credentials)
      assert session.credentials == credentials
      assert session.account_id == "u360641ae"
      assert session.api_url == "https://api.fastmail.com/jmap/api/"
      assert session.event_source_url == "https://api.fastmail.com/jmap/event/"
    end

    test "fails to connect with bad credentials" do
      credentials = Fastmail.Jmap.Credentials.null()

      assert {:error, error} = Fastmail.Jmap.Session.new(credentials)
      assert error.message =~ "Authorization"
    end
  end

  describe "connecting - null mode" do
    test "fails to connect with bad credentials" do
      null_config =
        NullConfig.new(
          on_get_session: fn ->
            RuntimeError.exception("non-existing domain")
          end
        )

      assert {:error, error} = Fastmail.Jmap.Session.null(null_config)
      assert error.message =~ "domain"
    end

    test "connects OK with default null config" do
      null_config = NullConfig.new()
      assert %Session{} = session = Fastmail.Jmap.Session.null(null_config)
      assert session.account_id == "some-account-id"
      assert session.event_source_url == "https://myserver.com/events"
      assert session.api_url == "https://myserver.com/api"
    end
  end

  describe "creating a new instance from a response JSON map" do
    test "it can be configured as a connected session" do
      data = %{
        "accounts" => %{
          "an-account-id" => %{}
        },
        "eventSourceUrl" => "https://myserver.com/events",
        "apiUrl" => "https://myserver.com/api"
      }

      session = Fastmail.Jmap.Session.new(data, Fastmail.Jmap.null())
      assert session.account_id == "an-account-id"
      assert session.api_url == "https://myserver.com/api"
    end
  end

  describe "connecting to the event source" do
    @tag :skip
    test "it can open the stream" do
      session = Fastmail.Jmap.Session.null(events: ["message one", "message two"])
      {:ok, response} = session |> Fastmail.Jmap.Session.event_stream()

      messages = Enum.map(response.body, fn message -> message end)
      assert messages == ["message one", "message two"]
    end
  end
end
