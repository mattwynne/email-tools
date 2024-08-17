defmodule EmailTools.FastmailClient do
  alias EmailTools.FastmailEvents
  alias EmailTools.ServerSentEvent
  use GenServer
  use Tesla

  plug(Tesla.Middleware.SSE, only: :data)
  adapter(Tesla.Adapter.Finch, name: EmailTools.Finch)

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")
    state = %{token: token, ui: self()}
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
          |> stream_events()

        _ ->
          state
      end

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    state = state |> Map.put(:latest, event["changed"])

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  defp stream_events(state) do
    FastmailEvents.new(state.token) |> FastmailEvents.stream(state.session)

    state
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
      {"authorization", "Bearer #{token}"}
    ]
  end
end
