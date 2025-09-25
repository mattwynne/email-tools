defmodule Fastmail.Jmap.Session do
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.Requests.MethodCalls

  defstruct [:credentials, :account_id, :api_url, :event_source_url, :build_method_calls_request]

  def null(opts \\ []) do
    new(Credentials.null(),
      get_session: Keyword.get(opts, :get_session, GetSession.null()),
      method_calls: Keyword.get(opts, :method_calls, fn _, _ -> MethodCalls.null() end)
    )
  end

  def new(%Credentials{} = credentials, opts \\ []) do
    %Req.Request{} = get_session = Keyword.get(opts, :get_session, GetSession.new(credentials))

    build_method_calls_request =
      Keyword.get(opts, :method_calls, fn session, method_calls ->
        MethodCalls.new(
          session.api_url,
          session.credentials.token,
          method_calls
        )
      end)

    with {:ok, body} <- request(get_session) do
      %__MODULE__{
        credentials: credentials,
        account_id: account_id(body),
        api_url: api_url(body),
        event_source_url: event_source_url(body),
        build_method_calls_request: build_method_calls_request
      }
    end
  end

  def method_calls(%__MODULE__{} = session, method_calls_mod, params \\ []) do
    params =
      struct(
        Module.concat(method_calls_mod, Params),
        Keyword.merge(params, account_id: session.account_id)
      )

    method_calls = method_calls_mod.new(params)
    request = session.build_method_calls_request.(session, method_calls)

    {:ok, body} = request(request)
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
