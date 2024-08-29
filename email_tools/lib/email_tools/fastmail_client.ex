defmodule EmailTools.FastmailClient do
  alias EmailTools.FastmailEvents
  alias EmailTools.ServerSentEvent
  use GenServer

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")

    state = %{
      token: token,
      ui: self(),
      status: "Connecting to Fastmail servers"
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
    send(state.ui, {:state, state})

    response =
      Req.get!(
        "https://api.fastmail.com/jmap/session",
        headers: headers(state)
      )

    send(state.ui, {:response, response})

    state =
      case response do
        %{status: 200} ->
          session = response.body

          state =
            state
            |> Map.put(:session, session)
            |> Map.put(:status, "Connecting to event stream")

          send(state.ui, {:state, state})

          state
          |> stream_events()

        _ ->
          state
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, data}, state) do
    dbg([:client, :event, data])
    changes = data["changes"]
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
    response =
      Req.post!(
        State.api_url(state),
        body:
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
    url = state.session["eventSourceUrl"]
    {:ok, events} = FastmailEvents.start_link(%{url: url, token: state.token, last_event_id: "0"})

    state |> Map.put(:events, events)
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
