defmodule EmailTools.FastmailClient do
  alias EmailTools.FastmailEvents
  alias EmailTools.ServerSentEvent
  use GenServer
  use Tesla

  plug(Tesla.Middleware.SSE, only: :data)
  adapter(Tesla.Adapter.Finch, name: EmailTools.Finch)

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")

    state = %{
      token: token,
      ui: self(),
      status: "Connecting"
    }

    {:ok, pid} = GenServer.start_link(__MODULE__, state, opts)
    pid
  end

  def connect(pid) do
    GenServer.cast(pid, :connect)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:connect, state) do
    response =
      get(
        "https://api.fastmail.com/jmap/session",
        headers: headers(state)
      )

    send(state.ui, {:response, response})

    state =
      case response do
        {:ok, response} ->
          session = Jason.decode!(response.body)

          state
          |> Map.put(:session, session)
          |> Map.put(:status, "Connecting to event stream")
          |> stream_events()

        _ ->
          state
      end

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, %{"changed" => changes}}, state) do
    account_id = State.account_id(state)
    handle_changes(changes, account_id, state)

    state =
      state
      |> Map.put(:latest, changes)
      |> Map.put(:status, "Handling update event")

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  def handle_cast({:method_call, method, params}, state) do
    {:ok, response} =
      post(
        State.api_url(state),
        Jason.encode!(%{
          using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
          methodCalls: [[method, params, "a"]]
        }),
        headers: headers(state)
      )

    result = Jason.decode!(response.body)
    method_response = Enum.at(result["methodResponses"], 0)

    GenServer.cast(
      self(),
      {:method_response, method_response}
    )

    {:noreply, state}
  end

  def handle_cast({:method_response, ["Thread/changes", result, _]}, state) do
    GenServer.cast(
      self(),
      {:method_call, "Thread/get",
       %{
         accountId: State.account_id(state),
         ids: result["updated"]
       }}
    )

    {
      :noreply,
      state
    }
  end

  def handle_cast({:method_response, [method, result, _]}, state) do
    dbg([method, result])
    {:noreply, state}
  end

  defp stream_events(state) do
    FastmailEvents.new(state.token) |> FastmailEvents.stream(state.session)

    state
  end

  defp handle_changes(changes, account_id, %{latest: old_changes} = state) do
    new = changes[account_id]
    old = old_changes[account_id]
    dbg(old)

    ["Email", "Mailbox", "Thread"]
    |> Enum.each(fn type ->
      if old[type] != new[type] do
        get_changes(type, old[type], state)
      end
    end)
  end

  defp handle_changes(_, _, _), do: nil

  defp get_changes(type, since, state) do
    GenServer.cast(
      self(),
      {
        :method_call,
        "#{type}/changes",
        %{
          accountId: State.account_id(state),
          sinceState: since
        }
      }
    )
  end

  @impl true
  # TODO: wrap all this in a FastmailEvents Genserver
  def handle_info({_ref, {:data, payload}}, state) do
    case ServerSentEvent.parse(payload) do
      %{event: "state", data: data} ->
        event = Jason.decode!(data)
        GenServer.cast(self(), {:event, event})

      _ ->
        nil
    end

    {:noreply, state}
  end

  def handle_info({_ref, {:error, %Mint.TransportError{reason: :timeout}}}, state) do
    dbg("Attempting to reconnect")
    stream_events(state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    dbg([:unhandled, msg])
    {:noreply, state}
  end

  defp headers(%{token: token}) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]
  end
end
