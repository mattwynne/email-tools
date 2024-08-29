defmodule EmailTools.FastmailEvents do
  alias EmailTools.FastmailEvent

  def start_link(state) do
    GenServer.start_link(
      __MODULE__,
      state
      |> Map.put(:client, self())
    )
  end

  def init(state) do
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  def handle_cast(:connect, state) do
    # TODO: last_event_id is irrelevant until we get some kind of persistence.
    headers = %{
      "accept" => "text/event-stream",
      "last-event-id" => state.last_event_id
    }

    %{body: stream} =
      Req.get!(state.url,
        headers: headers,
        auth: {:bearer, state.token},
        into: :self,
        receive_timeout: :infinity
      )

    Enum.each(stream, fn message ->
      event = FastmailEvent.new(message)

      if !FastmailEvent.empty?(event) do
        GenServer.cast(state.client, {:event, event.data})
      end
    end)

    {:noreply, state}
  end
end
