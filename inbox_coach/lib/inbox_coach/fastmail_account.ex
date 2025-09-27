defmodule InboxCoach.FastmailAccount do
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias InboxCoach.Mailbox
  alias InboxCoach.Email
  alias InboxCoach.State
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
          account_state: State.new()
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
    dbg([:client, :event, data])
    changes = data["changed"]
    handle_changes(changes, state.session.account_id, state)

    state =
      state
      |> Map.put(:latest, changes)
      |> emit()

    {:noreply, state}
  end

  @impl true
  def handle_info(["Mailbox/get", payload, _], state) do
    Enum.each(payload["list"], fn mailbox ->
      state
      |> execute(
        Fastmail.Jmap.MethodCalls.QueryAllEmails,
        in_mailbox: mailbox["id"]
      )
    end)

    state =
      state
      |> Map.put(
        :account_state,
        State.with_mailboxes(state.account_state, payload)
      )

    emit(state)
    {:noreply, state}
  end

  def handle_info(["Email/query", result, _], state) do
    state =
      state
      |> Map.put(
        :account_state,
        State.set_emails_for_mailbox(
          state.account_state,
          result["filter"]["inMailbox"],
          result["ids"]
        )
      )

    emit(state)
    {:noreply, state}
  end

  def handle_info(["Email/changes", result, _], state) do
    ids = result["updated"]

    execute(
      state,
      Fastmail.Jmap.MethodCalls.GetEmailsByIds,
      ids: ids
    )

    {:noreply, state}
  end

  def handle_info(["Email/get", result, _], state) do
    emails = result["list"]

    state =
      Enum.reduce(emails, state, fn email, state ->
        {added, removed} = state.account_state |> State.changes(email)

        Enum.each(added, fn mailbox_id ->
          [
            :email_added,
            System.os_time(:millisecond),
            Email.subject(email),
            Mailbox.name(State.mailbox(state.account_state, mailbox_id))
          ]
        end)

        Enum.each(removed, fn _mailbox_id ->
          # TODO: how do we broadcast this?
          nil
          # dbg([
          #   :email_removed,
          #   System.os_time(:millisecond),
          #   Email.subject(email),
          #   Mailbox.name(State.mailbox(state, mailbox_id))
          # ])
        end)

        account_state =
          Enum.reduce(
            removed,
            state.account_state,
            fn mailbox_id, account_state ->
              account_state |> State.remove_from_mailbox(mailbox_id, email |> Email.id())
            end
          )

        account_state =
          Enum.reduce(
            added,
            account_state,
            fn mailbox_id, account_state ->
              account_state |> State.add_to_mailbox(mailbox_id, email |> Email.id())
            end
          )

        Map.put(state, :account_state, account_state)
      end)

    emit(state)

    {:noreply, state}
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
    dbg(old)

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
      State.to_event(state.account_state)
    )

    state
  end

  defp ok(state), do: {:ok, state}

  def execute(%{session: session}, method_calls_mod, params \\ []) do
    session
    |> Session.execute(method_calls_mod, params)
    |> Enum.each(fn response -> send(self(), response) end)
  end
end
