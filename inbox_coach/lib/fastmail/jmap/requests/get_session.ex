defmodule Fastmail.Jmap.Requests.GetSession do
  alias Fastmail.Jmap.Credentials

  def new(%Credentials{token: token}) do
    Req.new(
      method: :get,
      url: "https://api.fastmail.com/jmap/session",
      headers: [
        {"accept", "application/json"}
      ],
      auth: {:bearer, token}
    )
  end

  def null(opts \\ [])

  def null(opts) when is_list(opts) do
    account_id = Keyword.get(opts, :account_id, "some-account-id")

    null(
      Req.Response.new(
        status: 200,
        body: %{
          "accounts" => %{
            account_id => %{}
          },
          "eventSourceUrl" => "https://myserver.com/events",
          "apiUrl" => "https://myserver.com/api"
        }
      )
    )
  end

  def null(response) do
    Req.new(
      adapter: fn request ->
        {
          request,
          response
        }
      end
    )
  end
end
