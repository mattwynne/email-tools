defmodule Fastmail.Jmap do
  alias Fastmail.Jmap.Credentials

  defstruct [:get_session, :get_event_source, :token]

  defmodule Get do
    def session(token) do
      Req.new(
        method: :get,
        url: "https://api.fastmail.com/jmap/session",
        headers: [
          {"accept", "application/json"}
        ],
        auth: {:bearer, token}
      )
    end

    def event_source(token, url) do
      Req.new(
        method: :get,
        url: url,
        headers: [
          {"accept", "text/event-stream"}
          # "last-event-id" => state.last_event_id
        ],
        auth: {:bearer, token},
        into: :self,
        receive_timeout: :infinity
      )
    end
  end

  def null(opts \\ []) do
    noop = fn request -> {request, Req.Response.new()} end

    new(%__MODULE__{
      get_session: fn _token -> Req.new(adapter: opts[:get_session] || noop) end,
      get_event_source: fn _token, _url -> Req.new(adapter: opts[:get_event_source] || noop) end,
      token: :a_token
    })
  end

  def new(%Credentials{token: token}) do
    new(%__MODULE__{
      get_session: &Get.session/1,
      get_event_source: &Get.event_source/2,
      token: token
    })
  end

  def new(%__MODULE__{} = web_service) do
    web_service
  end

  def get_session(web_service) do
    case Req.request(web_service.get_session.(web_service.token)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> Fastmail.Jmap.Session.new(web_service)}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end

  def get_event_source(web_service, url) do
    # TODO: handle errors
    # TODO: test me
    Req.request(web_service.get_event_source.(web_service.token, url))
  end
end
