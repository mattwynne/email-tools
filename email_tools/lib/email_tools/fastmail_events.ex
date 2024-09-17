defmodule EmailTools.FastmailEvents do
  alias EmailTools.FastmailEvent

  def open_stream(session) do
    state = %{
      client: self(),
      session: session,
      last_event_id: "0"
    }

    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  def init(state) do
    GenServer.cast(self(), :connect)
    {:ok, state}
  end

  def handle_cast(:connect, state) do
    # TODO: last_event_id is irrelevant until we get some kind of persistence.

    # TODO: factor out onto WebService
    result = state.session |> Fastmail.Session.event_stream()
    # headers = %{
    #   "accept" => "text/event-stream",
    #   "last-event-id" => state.last_event_id
    # }
    # Req.get(state.url,
    #   headers: headers,
    #   auth: {:bearer, state.token},
    #   into: :self,
    #   receive_timeout: :infinity
    # )

    case result do
      {:ok, response} ->
        Enum.each(response.body, fn message ->
          event = FastmailEvent.new(message)

          if !FastmailEvent.empty?(event) do
            GenServer.cast(state.client, {:event, event.data})
          end
        end)

      {:error, error} ->
        dbg(["EventSource connection failed: #{Exception.message(error)}, retrying"])
        GenServer.cast(self(), :connect)
    end

    {:noreply, state}
  end
end
