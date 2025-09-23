defmodule EmailTools.FastmailAccount do
  alias EmailTools.Mailbox
  alias EmailTools.Email
  alias EmailTools.State
  alias EmailTools.FastmailEvents
  alias EmailTools.Accounts
  use GenServer

  def start_link(opts \\ []) do
    # TODO: these can move outside this thing
    user = Keyword.fetch!(opts, :user)
    token = Accounts.get_user_fastmail_api_key(user)

    GenServer.start_link(
      __MODULE__,
      [token: token, pubsub_channel: pubsub_channel_for(user)],
      opts
    )
  end

  def pubsub_channel_for(user) do
    "fastmail-account:#{user.id}"
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  @impl true
  def init(token: token, pubsub_channel: pubsub_channel) do
    credentials = %Fastmail.Jmap.Credentials{token: token}

    with %Fastmail.Jmap.Session{} = session <- Fastmail.Jmap.Session.new(credentials) do
      %{
        pubsub_channel: pubsub_channel,
        session: session,
        emails_by_mailbox: %{}
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
    client_state = Map.take(state, [:mailboxes, :emails_by_mailbox])
    {:reply, client_state, state}
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
      |> State.request(
        Fastmail.Jmap.MethodCalls.QueryAllEmails.new(state.session.account_id, mailbox["id"])
      )
    end)

    state = state |> Map.put(:mailboxes, payload)

    emit(state)
    {:noreply, state}
  end

  def handle_info(["Email/query", result, _], state) do
    state =
      state
      |> Map.put(
        :emails_by_mailbox,
        Map.put(
          state.emails_by_mailbox,
          result["filter"]["inMailbox"],
          result["ids"]
        )
      )

    emit(state)
    {:noreply, state}
  end

  def handle_info(["Email/changes", result, _], state) do
    ids = result["updated"]

    State.request(
      state,
      Fastmail.Jmap.MethodCalls.GetEmailsByIds.new(state.session.account_id, ids)
    )

    {:noreply, state}
  end

  def handle_info(["Email/get", result, _], state) do
    emails = result["list"]

    state =
      Enum.reduce(emails, state, fn email, state ->
        {added, removed} = state |> State.changes(email)

        Enum.each(added, fn mailbox_id ->
          [
            :email_added,
            System.os_time(:millisecond),
            Email.subject(email),
            Mailbox.name(State.mailbox(state, mailbox_id))
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

        state =
          Enum.reduce(
            removed,
            state,
            fn mailbox_id, state ->
              state |> State.remove_from_mailbox(mailbox_id, email |> Email.id())
            end
          )

        Enum.reduce(
          added,
          state,
          fn mailbox_id, state ->
            state |> State.add_to_mailbox(mailbox_id, email |> Email.id())
          end
        )
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
        State.request(
          state,
          Fastmail.Jmap.MethodCalls.GetAllChanged.new(state.session.account_id, type, old[type])
        )
      end
    end)

    state
  end

  defp handle_changes(_, _, _), do: nil

  defp fetch_initial_state(state) do
    State.request(
      state,
      [
        [
          "AddressBook/get",
          %{
            accountId: state.session.account_id,
            ids: nil
          },
          "contacts"
        ],
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
      state.pubsub_channel,
      State.to_event(state)
    )

    state
  end

  defp ok(state), do: {:ok, state}
end
