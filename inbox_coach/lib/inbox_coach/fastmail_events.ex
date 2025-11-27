defmodule InboxCoach.FastmailEvents do
  alias Fastmail.Jmap.EventSource
  alias InboxCoach.FastmailEvent
  require Logger

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
    Logger.info("[FastmailEvents] Connecting to EventSource stream...")

    case state.session.event_source |> EventSource.stream() do
      {:ok, response} ->
        Logger.info("[FastmailEvents] EventSource stream connected successfully")

        Enum.each(response.body, fn message ->
          Logger.debug(
            "[jmap-event] #{inspect(message, pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
          )

          event = FastmailEvent.new(message)

          if !FastmailEvent.empty?(event) do
            GenServer.cast(state.client, {:event, event.data})
          end
        end)

        Logger.warning("[FastmailEvents] EventSource stream ended unexpectedly - no automatic reconnection implemented")

      {:error, error} ->
        Logger.warning("[FastmailEvents] EventSource connection failed: #{Exception.message(error)}, retrying...")
        GenServer.cast(self(), :connect)
    end

    {:noreply, state}
  end
end
