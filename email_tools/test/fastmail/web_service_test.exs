defmodule Fastmail.WebServiceTest do
  alias Fastmail.WebService
  use ExUnit.Case, async: true

  describe "fetching a session" do
    @tag :online
    test "it calls the fastmail servers to connect" do
      token = System.get_env("FASTMAIL_API_TOKEN")
      web_service = WebService.create(token: token)
      {:ok, _session} = web_service |> WebService.get_session()
    end

    test "it fails with a bad token" do
      web_service =
        WebService.create_null(
          get_session: fn request ->
            {
              request,
              Req.Response.new(status: 301, body: "Authorization header not a valid format")
            }
          end
        )

      {:error, error} = web_service |> WebService.get_session()

      assert Exception.message(error) |> String.trim() ==
               "Authorization header not a valid format"
    end

    test "it fails with a bad URL" do
      web_service =
        WebService.create_null(
          get_session: fn request ->
            {
              request,
              RuntimeError.exception("non-existing domain")
            }
          end
        )

      {:error, error} = web_service |> WebService.get_session()

      assert Exception.message(error) |> String.trim() == "non-existing domain"
    end
  end
end
