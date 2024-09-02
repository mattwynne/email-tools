defmodule Fastmail.SessionTest do
  use ExUnit.Case, async: true

  describe "connecting to fastmail for real" do
    @tag :online
    test "it calls the fastmail servers to connect" do
      token = System.get_env("FASTMAIL_API_TOKEN")
      {:ok, session} = Fastmail.Session.fetch(token: token)
      assert session.account_id == "u360641ae"
    end
  end

  describe "failure modes when fetching" do
    test "it fails with a bad token" do
      fake = fn request ->
        {request, Req.Response.new(status: 301, body: "Authorization header not a valid format")}
      end

      {:error, error} = Fastmail.Session.fetch(req: Req.new(adapter: fake))

      assert Exception.message(error) |> String.trim() ==
               "Authorization header not a valid format"
    end

    test "it fails with a bad URL" do
      fake = fn request ->
        {request, RuntimeError.exception("non-existing domain")}
      end

      {:error, error} = Fastmail.Session.fetch(req: Req.new(adapter: fake))

      assert Exception.message(error) |> String.trim() ==
               "non-existing domain"
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

      session = Fastmail.Session.parse(data)
      assert session.account_id == "an-account-id"
      assert session.event_source_url == "https://myserver.com/events"
      assert session.api_url == "https://myserver.com/api"
    end
  end
end
