defmodule Fastmail.WebService do
  def get_session(opts \\ []) do
    token = opts[:token]
    req = opts[:req] || Fastmail.Request.session(token)

    case Req.request(req) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> Fastmail.Session.parse()}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end
end
