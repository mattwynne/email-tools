defmodule Fastmail.Jmap.SessionTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.Session

  describe "connecting" do
    test "connects when created" do
      credentials = Fastmail.Jmap.Credentials.from_environment()
      session = Fastmail.Jmap.Session.new(credentials)
      assert session.credentials == credentials
      # assert session.account_id == "u360641ae" # Matt
      assert session.account_id == "u4d014069" # Test
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
      assert {:error, error} =
               Fastmail.Jmap.Session.null(
                 response:
                   Req.Response.new(status: 301, body: "Authorization header not a valid format")
               )

      assert error.message =~ "Authorization"
    end

    test "fails with a bad URL" do
      assert {:error, error} =
               Fastmail.Jmap.Session.null(response: RuntimeError.exception("non-existing domain"))

      assert error.message =~ "domain"
    end

    test "connects OK with default null config" do
      assert %Session{} = session = Fastmail.Jmap.Session.null()
      assert session.account_id == "some-account-id"
      assert session.event_source_url == "https://myserver.com/events"
      assert session.api_url == "https://myserver.com/api"
    end
  end
end
