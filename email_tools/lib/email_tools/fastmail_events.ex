defmodule EmailTools.FastmailEvents do
  alias EmailTools.FastmailEvent

  def start_link(state) do
    GenServer.start_link(
      __MODULE__,
      state
      |> Map.put(:client, self())
    )
  end

  # Start connecting to the endpoint as soon as client is started.
  def init(state) do
    dbg("init!")
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  def handle_cast(:connect, state) do
    headers = %{
      "accept" => "text/event-stream",
      "authorization" => "Bearer #{state.token}"
    }

    headers =
      if state.last_event_id do
        Map.put(headers, "last-event-id", state.last_event_id)
      else
        headers
      end

    response = Req.get!(state.url, headers: headers, into: :self, receive_timeout: :infinity)

    state =
      Enum.reduce(response.body, state, fn message, state ->
        dbg(message)
        event = FastmailEvent.new(message)

        if !FastmailEvent.empty?(event) do
          dbg(event)
          GenServer.cast(state.client, {:event, event.data})
          %{state | last_event_id: event.id}
        else
          state
        end
      end)

    dbg(state)
    {:noreply, state}
  end
end
