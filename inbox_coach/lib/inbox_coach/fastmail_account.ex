defmodule InboxCoach.FastmailAccount do
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias Fastmail.Jmap.AccountState
  alias InboxCoach.FastmailEvents
  use GenServer

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
  def handle_cast({:event, data}, state) do
    changes = data["changed"]
    handle_changes(changes, state.session.account_id, state)

    state
    |> Map.put(:latest, changes)
    |> emit()
    |> noreply()
  end

  @impl true
  def handle_info(%GetAllMailboxes.Response{mailboxes: mailboxes} = response, state) do
    # TODO: swap these - do this after the state has been updated, and iterate the mailboxes in the state instead of the response
    Enum.each(
      mailboxes,
      fn mailbox -> state |> execute(QueryAllEmails, in_mailbox: mailbox.id) end
    )

    state
    |> Map.put(
      :account_state,
      GetAllMailboxes.Response.apply_to(response, state.account_state)
    )
    |> emit()
    |> noreply()
  end

  def handle_info(
        response = %QueryAllEmails.Response{},
        state
      ) do
    # TODO: reduce duplication with GetAllMailboxes handler - use a protocol and a generic handler?
    state
    |> Map.put(
      :account_state,
      QueryAllEmails.Response.apply_to(response, state.account_state)
    )
    |> emit()
    |> noreply()
  end

  def handle_info(response = %GetAllChanged.Response{}, state) do
    state
    |> Map.put(
      :account_state,
      GetAllChanged.Response.apply_to(response, state.account_state)
    )
    |> emit()
    |> noreply()
  end

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

    ["Email", "Mailbox", "Thread"]
    |> Enum.each(fn type ->
      if old[type] != new[type] do
        state |> execute(GetAllChanged, type: type, since_state: old[type])
      end
    end)

    state
  end

  defp handle_changes(_, _, _), do: nil

  defp fetch_initial_state(state) do
    state |> tap(&execute(&1, GetAllMailboxes))
  end

  defp emit(state) do
    Phoenix.PubSub.broadcast(
      InboxCoach.PubSub,
      state.pubsub_topic,
      {:state, state.account_state}
    )

    state
  end

  defp ok(state), do: {:ok, state}
  defp noreply(state), do: {:noreply, state}

  def execute(%{session: session}, method_calls_mod, params \\ []) do
    response = session |> Session.execute(method_calls_mod, params)

    send(self(), response)
  end
end
