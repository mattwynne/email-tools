defmodule Fastmail.Jmap.Session do
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.Requests.MethodCalls
  alias Fastmail.Jmap.EventSource

  defstruct [
    :credentials,
    :account_id,
    :api_url,
    :event_source_url,
    :build_method_calls_request,
    :event_source
  ]

  def null(opts \\ []) do
    new(Credentials.null(),
      get_session: Keyword.get(opts, :get_session, GetSession.null()),
      method_calls: Keyword.get(opts, :method_calls, MethodCalls.null()),
      event_source: Keyword.get(opts, :event_source, EventSource.null())
    )
  end

  def new(%Credentials{} = credentials, opts \\ []) do
    %Req.Request{} = get_session = Keyword.get(opts, :get_session, GetSession.new(credentials))

    build_method_calls_request = fn session, method_calls ->
      Keyword.get(
        opts,
        :method_calls,
        MethodCalls.new(
          session.api_url,
          session.credentials.token,
          method_calls
        )
      )
    end

    with {:ok, body} <- request(get_session) do
      event_source_url = event_source_url(body)

      event_source =
        Keyword.get(opts, :event_source, EventSource.new(credentials, event_source_url))

      %__MODULE__{
        credentials: credentials,
        account_id: account_id(body),
        api_url: api_url(body),
        event_source_url: event_source_url,
        build_method_calls_request: build_method_calls_request,
        event_source: event_source
      }
    end
  end

  def execute(%__MODULE__{} = session, method_calls_mod, params \\ []) do
    method_calls =
      struct(
        Module.concat(method_calls_mod, Params),
        Keyword.merge(params, account_id: session.account_id)
      )
      |> method_calls_mod.new()

    {:ok, body} =
      session.build_method_calls_request.(session, method_calls)
      |> request

    body["methodResponses"]
  end

  defp request(%Req.Request{} = request) do
    case Req.request(request) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp account_id(data) do
    Map.keys(data["accounts"]) |> Enum.at(0)
  end

  defp event_source_url(data) do
    data["eventSourceUrl"]
  end

  defp api_url(data) do
    data["apiUrl"]
  end
end
