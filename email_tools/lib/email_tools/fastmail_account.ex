defmodule EmailTools.FastmailAccount do
  alias EmailTools.Mailbox
  alias EmailTools.Email
  alias EmailTools.State
  alias EmailTools.FastmailEvents
  use GenServer

  def start_link(opts \\ []) do
    token = Keyword.fetch!(opts, :token)
    pubsub_topic = Keyword.fetch!(opts, :pubsub_topic)

    GenServer.start_link(
      __MODULE__,
      [
        token: token,
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
  def init(token: token, pubsub_topic: pubsub_topic) do
    credentials = %Fastmail.Jmap.Credentials{token: token}

    with %Fastmail.Jmap.Session{} = session <- Fastmail.Jmap.Session.new(credentials) do
      %{
        pubsub_topic: pubsub_topic,
        session: session,
        account_state: State.new()
      }
      |> emit()
      |> stream_events()
      |> fetch_initial_state()
      |> ok()
    else
      {:error, error} -> {:stop, error}
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
      |> request(
        Fastmail.Jmap.MethodCalls.QueryAllEmails.new(state.session.account_id, mailbox["id"])
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

    request(
      state,
      Fastmail.Jmap.MethodCalls.GetEmailsByIds.new(state.session.account_id, ids)
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

    ["Email"]
    |> Enum.each(fn type ->
      if old[type] != new[type] do
        request(
          state,
          Fastmail.Jmap.MethodCalls.GetAllChanged.new(state.session.account_id, type, old[type])
        )
      end
    end)

    state
  end

  defp handle_changes(_, _, _), do: nil

  defp fetch_initial_state(state) do
    request(
      state,
      [
        [
          "Mailbox/get",
          %{
            accountId: state.session.account_id,
            ids: nil
          },
          "mailboxes"
        ]
      ]
    )

    state
  end

  defp emit(state) do
    Phoenix.PubSub.broadcast(
      EmailTools.PubSub,
      state.pubsub_topic,
      State.to_event(state.account_state)
    )

    state
  end

  defp ok(state), do: {:ok, state}

  def request(state, request) do
    # TODO: move to session
    Req.request!(
      Fastmail.Jmap.Request.method_calls(
        state.session.api_url,
        state.session.credentials.token,
        request
      )
    )
    |> then(& &1.body["methodResponses"])
    |> Enum.each(fn response -> send(self(), response) end)
  end
end
