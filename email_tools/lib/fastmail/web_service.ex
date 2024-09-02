defmodule Fastmail.WebService do
  defstruct [:get_session]

  def create_null(opts \\ []) do
    noop = fn request -> {request, Req.Response.new()} end

    %__MODULE__{
      get_session: Req.new(adapter: opts[:get_session] || noop)
    }
  end

  def create(opts) do
    token = Keyword.fetch!(opts, :token)

    %__MODULE__{
      get_session: Fastmail.Request.get_session(token)
    }
  end

  def get_session(web_service) do
    case Req.request(web_service.get_session) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> Fastmail.Session.parse()}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end
end
