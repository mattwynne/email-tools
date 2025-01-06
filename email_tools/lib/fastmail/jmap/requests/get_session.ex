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
