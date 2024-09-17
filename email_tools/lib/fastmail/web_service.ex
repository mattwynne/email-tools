defmodule Fastmail.WebService do
  defstruct [:get_session, :get_event_source, :token]

  def create_null(opts \\ []) do
    noop = fn request -> {request, Req.Response.new()} end

    new(%__MODULE__{
      get_session: fn _token -> Req.new(adapter: opts[:get_session] || noop) end,
      get_event_source: fn _token, _url -> Req.new(adapter: opts[:get_event_source] || noop) end,
      token: :a_token
    })
  end

  def create(opts) do
    token = Keyword.fetch!(opts, :token)

    new(%__MODULE__{
      get_session: &Fastmail.Request.get_session/1,
      get_event_source: &Fastmail.Request.get_event_source/2,
      token: token
    })
  end

  defp new(%__MODULE__{} = web_service) do
    web_service
  end

  def get_session(web_service) do
    case Req.request(web_service.get_session.(web_service.token)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> Fastmail.Session.new(web_service)}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_event_source(web_service, url) do
    # TODO: handle errors
    dbg(url)
    Req.request(web_service.get_event_source.(web_service.token, url))
  end
end
