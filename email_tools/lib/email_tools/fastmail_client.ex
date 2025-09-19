# TODO: Rename to FastmailAccount or ConnectedFastmailAccount - this will be the live state of an account
defmodule EmailTools.FastmailClient do
  alias EmailTools.Mailbox
  alias EmailTools.Email
  alias EmailTools.State
  alias EmailTools.FastmailEvents
  alias EmailTools.Accounts
  use GenServer

  def start_link(opts \\ []) do
    user = Keyword.fetch!(opts, :user)
    token = Accounts.get_user_fastmail_api_key(user)

    # TODO: should we do this here or in init?
    # TODO: add the web_service here
    state = %{
      token: token,
      ui: self(),
      mailboxes: nil,
      emails_by_mailbox: %{}
    }

    {:ok, pid} = GenServer.start_link(__MODULE__, state, opts)
    pid
  end

  def connect(pid) do
    GenServer.cast(pid, :connect)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:connect, state) do
    emit(state)

    credentials = %Fastmail.Jmap.Credentials{token: state.token}

    state =
      case Fastmail.Jmap.Session.new(credentials) do
        %Fastmail.Jmap.Session{} = session ->
          state = state |> Map.put(:session, session)
          dbg(session)

          emit(state)

          state
          |> stream_events()
          |> fetch_initial_state()

        {:error, error} ->
          dbg(["Connection failed: #{Exception.message(error)}, retrying"])
          GenServer.cast(self(), :connect)
          state
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, data}, state) do
    dbg([:client, :event, data])
    changes = data["changed"]
    handle_changes(changes, state.session.account_id, state)

    state =
      state
      |> Map.put(:latest, changes)

    emit(state)
    {:noreply, state}
  end

  def handle_cast({:method_call, method, params}, state) do
    # TODO: move this HTTP call onto Fastmail.Session.method_calls
    response =
      Req.request!(
        Fastmail.Jmap.Request.method_calls(
          state.session.api_url,
          state.token,
          [[method, params, "0"]]
        )
      )

    dbg(response)
    method_response = Enum.at(response.body["methodResponses"], 0)

    send(
      self(),
      method_response
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(["Mailbox/get", payload, _], state) do
    Enum.each(payload["list"], fn mailbox ->
      request(
        Fastmail.Jmap.MethodCalls.QueryAllEmails.new(state.session.account_id, mailbox["id"]),
        state
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

    request(
      Fastmail.Jmap.MethodCalls.GetEmailsByIds.new(state.session.account_id, ids),
      state
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
        request(
          Fastmail.Jmap.MethodCalls.GetAllChanged.new(state.session.account_id, type, old[type]),
          state
        )
      end
    end)

    state
  end

  defp handle_changes(_, _, _), do: nil

  defp request(request, state) do
    Req.request!(
      Fastmail.Jmap.Request.method_calls(
        state.session.api_url,
        state.token,
        request
      )
    )
    |> dbg()
    |> then(& &1.body["methodResponses"])
    |> Enum.each(fn response -> send(self(), response) end)
  end

  defp fetch_initial_state(state) do
    request(
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
      ],
      state
    )

    state
  end

  defp emit(state) do
    send(state.ui, {:state, Map.take(state, [:mailboxes, :emails_by_mailbox])})
    state
  end
end
