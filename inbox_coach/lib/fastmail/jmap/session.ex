defmodule Fastmail.Jmap.Session do
  require Logger
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.Requests.MethodCalls
  alias Fastmail.Jmap.EventSource

  defstruct [
    :credentials,
    :account_id,
    :api_url,
    :event_source_url,
    :execute,
    :event_source
  ]

  def null(opts \\ []) do
    Keyword.validate!(opts, [:get_session, :execute, :event_source])

    new(Credentials.null(),
      get_session: Keyword.get(opts, :get_session, GetSession.null()),
      execute: Keyword.get(opts, :execute, []),
      event_source: Keyword.get(opts, :event_source, EventSource.null())
    )
  end

  def new(%Credentials{} = credentials, opts \\ []) do
    %Req.Request{} = get_session = Keyword.get(opts, :get_session, GetSession.new(credentials))

    execute = Keyword.get(opts, :execute, :real)

    with {:ok, body} <- request(get_session) do
      event_source_url = event_source_url(body)

      event_source =
        Keyword.get(opts, :event_source, EventSource.new(credentials, event_source_url))

      %__MODULE__{
        credentials: credentials,
        account_id: account_id(body),
        api_url: api_url(body),
        event_source_url: event_source_url,
        execute: execute,
        event_source: event_source
      }
    end
  end

  def execute(%__MODULE__{} = session, mod), do: execute(session, mod, [])

  def execute(%__MODULE__{execute: stub}, mod, params) when is_list(stub) do
    (Enum.find_value(stub, fn
       {{^mod}, response} when params == [] ->
         response

       {{^mod, ^params}, response} ->
         response

       _ ->
         nil
     end) ||
       raise("No stub configured for #{inspect({mod, params})} in #{inspect(stub)}"))
    |> MethodCalls.null()
    |> log_request(mod, params)
    |> request_and_parse(mod)
  end

  def execute(
        %__MODULE__{api_url: api_url, account_id: account_id, credentials: %{token: token}},
        method_name,
        params
      )
      when is_binary(method_name) do
    params_map =
      params
      |> Enum.into(%{})
      |> Map.put("accountId", account_id)

    [[method_name, params_map, "0"]]
    |> MethodCalls.new(api_url, token)
    |> log_request
    |> request_and_parse(MethodCalls)
  end

  def execute(
        %__MODULE__{api_url: api_url, credentials: %{token: token}} = session,
        method_calls_mod,
        params
      )
      when is_atom(method_calls_mod) do
    struct(
      Module.concat(method_calls_mod, Params),
      Keyword.merge(params, account_id: session.account_id)
    )
    |> method_calls_mod.new()
    |> MethodCalls.new(api_url, token)
    |> log_request
    |> request_and_parse(method_calls_mod)
  end

  defp request_and_parse(%Req.Request{} = request, method_calls_mod) do
    {:ok, body} =
      request
      |> request

    Logger.debug(
      "[jmap-response] #{inspect(body, pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
    )

    body["methodResponses"]
    |> handle_response(method_calls_mod)
  end

  defp handle_response(response, method_calls_mod) do
    response_mod = Module.concat(method_calls_mod, Response)
    Code.ensure_loaded(response_mod)

    if function_exported?(response_mod, :new, 1) do
      response_mod.new(response)
    else
      response
    end
  end

  defp log_request(%Req.Request{body: nil} = request, mod, params) do
    Logger.debug(
      "[jmap-request] #{inspect([:stub, mod, params], pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
    )

    request
  end

  defp log_request(%Req.Request{body: body} = request) do
    Logger.debug(
      "[jmap-request] #{inspect(Jason.decode!(body), pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
    )

    request
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
