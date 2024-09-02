defmodule Fastmail.WebServiceTest do
  use ExUnit.Case, async: true

  describe "fetching a session" do
    @tag :online
    test "it calls the fastmail servers to connect" do
      token = System.get_env("FASTMAIL_API_TOKEN")
      {:ok, session} = Fastmail.WebService.get_session(token: token)
      assert session.account_id == "u360641ae"
    end

    test "it fails with a bad token" do
      fake = fn request ->
        {request, Req.Response.new(status: 301, body: "Authorization header not a valid format")}
      end

      {:error, error} = Fastmail.WebService.get_session(req: Req.new(adapter: fake))

      assert Exception.message(error) |> String.trim() ==
               "Authorization header not a valid format"
    end

    test "it fails with a bad URL" do
      fake = fn request ->
        {request, RuntimeError.exception("non-existing domain")}
      end

      {:error, error} = Fastmail.WebService.get_session(req: Req.new(adapter: fake))

      assert Exception.message(error) |> String.trim() ==
               "non-existing domain"
    end
  end
end
