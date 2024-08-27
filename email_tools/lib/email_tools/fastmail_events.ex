defmodule EmailTools.FastmailEvents do
  @behaviour ServerSentEvent.Client

  def start_link(state) do
    ServerSentEvent.Client.start_link(
      __MODULE__,
      state
      |> Map.put(:client, self())
    )
  end

  # Start connecting to the endpoint as soon as client is started.
  def init(state) do
    dbg("init!")
    {:connect, request(state), state}
  end

  # The client has successfully connected, or reconnected, to the event stream.
  def handle_connect(_response, state) do
    dbg("connected!")
    {:noreply, state}
  end

  # Retry connecting to endpoint 1 second after a failure to connect.
  def handle_connect_failure(reason, state) do
    dbg([:failed, reason])
    Process.sleep(1_000)
    {:connect, request(state), state}
  end

  # Immediatly try to reconnect when the connection is lost.
  def handle_disconnect(_, state) do
    {:connect, request(state), state}
  end

  # Update the running state of the client with the id of each event as it arrives.
  # This event id is used for reconnection.
  def handle_event(%{type: "state"} = event, state) do
    IO.puts("I just got a new event: #{inspect(event)}")
    GenServer.cast(state.client, {:event, Jason.decode!(Enum.at(event.lines, 0))})
    %{state | last_event_id: event.id}
  end

  def handle_event(event, state) do
    dbg(["Unhandled event:", event])
    state
  end

  # When stop message is received this process will exit with reason :normal.
  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  # Not a callback but helpful pattern for creating requests in several callbacks
  defp request(state) do
    result =
      Raxx.request(:GET, state.url)
      |> Raxx.set_header("accept", "text/event-stream")
      |> Raxx.set_header("authorization", "Bearer #{state.token}")

    if state.last_event_id do
      result |> Raxx.set_header("last-event-id", state.last_event_id)
    else
      result
    end
  end
end
