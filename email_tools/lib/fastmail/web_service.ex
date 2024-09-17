defmodule Fastmail.WebService do
  defstruct [:get_session, :token]

  def create_null(opts \\ []) do
    noop = fn request -> {request, Req.Response.new()} end

    new(fn _token -> Req.new(adapter: opts[:get_session] || noop) end, :a_token)
  end

  def create(opts) do
    token = Keyword.fetch!(opts, :token)

    new(&Fastmail.Request.get_session/1, token)
  end

  defp new(get_session, token) do
    %__MODULE__{get_session: get_session, token: token}
  end

  def get_session(web_service) do
    case Req.request(web_service.get_session.(web_service.token)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> Fastmail.Session.parse()}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end
end
