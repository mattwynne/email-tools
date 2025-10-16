defmodule InboxCoach.FastmailAccount do
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Session
  alias Fastmail.Jmap.MethodCalls.GetAllChanged
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
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
            State.mailbox(state.account_state, mailbox_id).name
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
  defp noreply(state), do: {:noreply, state}

  def execute(%{session: session}, method_calls_mod, params \\ []) do
    case session
         |> Session.execute(method_calls_mod, params) do
      [_] = responses ->
        responses
        |> Enum.each(fn response -> send(self(), response) end)

      %GetAllMailboxes.Response{} = response ->
        send(self(), response)

      %QueryAllEmails.Response{} = response ->
        send(self(), response)

      %GetAllChanged.Response{} = response ->
        send(self(), response)

      response ->
        raise "Unable to handle response #{inspect(response)} from #{method_calls_mod} with #{inspect(params)}"
    end
  end
end
