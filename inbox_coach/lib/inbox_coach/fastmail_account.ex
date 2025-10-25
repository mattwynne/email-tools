defmodule InboxCoach.FastmailAccount do
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias Fastmail.Jmap.AccountState
  alias InboxCoach.FastmailEvents
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    pubsub_topic = Keyword.fetch!(opts, :pubsub_topic)

    session =
      case Keyword.fetch(opts, :session) do
        {:ok, session} ->
          session

        :error ->
          token = Keyword.fetch!(opts, :token)
          credentials = %Fastmail.Jmap.Credentials{token: token}
          Session.new(credentials)
      end

    GenServer.start_link(
      __MODULE__,
      [
        session: session,
        pubsub_topic: pubsub_topic
      ],
      opts
    )
  end

  def pubsub_topic_for(user) do
    "fastmail-account:#{user.id}"
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  @impl true
  def init(session: session, pubsub_topic: pubsub_topic) do
    case session do
      %Session{} = session ->
        %{
          pubsub_topic: pubsub_topic,
          session: session,
          account_state: %AccountState{}
        }
        |> emit()
        |> stream_events()
        |> fetch_initial_state()
        |> ok()

      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.account_state, state}
  end

  @impl true
  def handle_cast({:event, data}, state = %{session: session}) do
    changes = data["changed"]
    handle_changes(changes, session.account_id, state)

    state
    |> Map.put(:latest, changes)
    |> emit()
    |> noreply()
  end

  def after_response_applied(state, %GetAllMailboxes.Response{} = _e) do
    Enum.reduce(
      state.account_state.mailboxes,
      state,
      fn mailbox, state ->
        state |> execute(QueryAllEmails, in_mailbox: mailbox.id)
      end
    )
  end

  def after_response_applied(
        state,
        %GetAllChanged.Response{type: :mailboxes, updated: changed_mailboxes}
      ) do
    Enum.reduce(
      changed_mailboxes,
      state,
      fn changed_mailbox, state ->
        state |> execute(QueryAllEmails, in_mailbox: changed_mailbox.id)
      end
    )
  end

  def after_response_applied(state, %GetAllChanged.Response{}) do
    state
  end

  def after_response_applied(state, %QueryAllEmails.Response{}) do
    state
  end

  def after_response_applied(state, msg) do
    dbg([:client, :unhandled, msg])
    {:noreply, state}
  end

  @impl true
  def handle_info({_task, response}, state = %{account_state: account_state}) do
    %response_mod{} = response

    state
    |> Map.put(
      :account_state,
      response_mod.apply_to(response, account_state)
    )
    |> emit()
    |> after_response_applied(response)
    |> noreply()
  end

  def handle_info({:DOWN, _, _, _, _}, state), do: state |> noreply()

  def handle_info(msg, state) do
    dbg([:client, :unhandled, msg])
    {:noreply, state}
  end

  defp stream_events(state) do
    state
    |> Map.put(
      :events,
      FastmailEvents.open_stream(state.session)
    )
  end

  defp handle_changes(changes, account_id, %{latest: old_changes} = state) do
    new = changes[account_id]
    old = old_changes[account_id]

    ["Email", "Mailbox", "Threads"]
    |> Enum.reduce(state, fn type, state ->
      if old[type] != new[type] do
        state |> execute(GetAllChanged, type: type, since_state: old[type])
      else
        state
      end
    end)
  end

  defp handle_changes(_, _, _), do: nil

  defp fetch_initial_state(state) do
    state |> execute(GetAllMailboxes)
  end

  defp emit(state) do
    Logger.debug("[emit] #{inspect(state, pretty: true, syntax_colors: IO.ANSI.syntax_colors())}")

    Phoenix.PubSub.broadcast(
      InboxCoach.PubSub,
      state.pubsub_topic,
      {:state, state.account_state}
    )

    state
  end

  defp ok(state), do: {:ok, state}
  defp noreply(state), do: {:noreply, state}

  def execute(state = %{session: session}, method_calls_mod, params \\ []) do
    Task.async(fn ->
      session |> Session.execute(method_calls_mod, params)
    end)

    state

    # %response_mod{} = response = session |> Session.execute(method_calls_mod, params)

    # state
    # |> Map.put(
    #   :account_state,
    #   response_mod.apply_to(response, state.account_state)
    # )
    # |> emit()
    # |> after_response_applied(response)
  end
end
