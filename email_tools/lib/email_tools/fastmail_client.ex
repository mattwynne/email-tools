defmodule EmailTools.FastmailClient do
  alias EmailTools.Mailbox
  alias EmailTools.Email
  alias EmailTools.State
  alias EmailTools.FastmailEvents
  use GenServer

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")

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
    send(state.ui, {:state, state})

    web_service = Fastmail.WebService.create(token: state.token)

    state =
      case web_service |> Fastmail.WebService.get_session() do
        {:ok, session} ->
          state = state |> Map.put(:session, session)

          send(state.ui, {:state, state})

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

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  def handle_cast({:method_call, method, params}, state) do
    # TODO: move this HTTP call onto Fastmail.WebService.method_calls
    response =
      Req.request!(
        Fastmail.Request.method_calls(
          state.session.api_url,
          state.token,
          [[method, params, "0"]]
        )
      )

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
      # TODO: factor out some kind of request builder
      method_call(
        "Email/query",
        %{
          accountId: state.session.account_id,
          filter: %{
            inMailbox: mailbox["id"]
          }
        }
      )
    end)

    state = state |> Map.put(:mailboxes, payload)

    send(state.ui, {:state, state})
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

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  def handle_info(["Email/changes", result, _], state) do
    ids = result["updated"]

    method_call("Email/get", %{
      accountId: state.session.account_id,
      ids: ids
    })

    {:noreply, state}
  end

  def handle_info(["Email/get", result, _], state) do
    emails = result["list"]

    state =
      Enum.reduce(emails, state, fn email, state ->
        {added, removed} = state |> State.changes(email)

        Enum.each(added, fn mailbox_id ->
          dbg([:email_added, Email.subject(email), Mailbox.name(State.mailbox(state, mailbox_id))])
        end)

        Enum.each(removed, fn mailbox_id ->
          dbg([
            :email_removed,
            Email.subject(email),
            Mailbox.name(State.mailbox(state, mailbox_id))
          ])
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

    # send(state.ui, {:state, state})

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
      FastmailEvents.open_stream(
        state.session.event_source_url,
        state.token
      )
    )
  end

  defp handle_changes(changes, account_id, %{latest: old_changes} = state) do
    new = changes[account_id]
    old = old_changes[account_id]
    dbg(old)

    ["Email"]
    |> Enum.each(fn type ->
      if old[type] != new[type] do
        get_changes(type, old[type], state)
      end
    end)

    state
  end

  defp handle_changes(_, _, _), do: nil

  defp get_changes(type, since, state) do
    method_call(
      "#{type}/changes",
      %{
        accountId: state.session.account_id,
        sinceState: since
      }
    )
  end

  defp fetch_initial_state(state) do
    method_call(
      "Mailbox/get",
      %{
        accountId: state.session.account_id,
        ids: nil
      }
    )

    state
  end

  defp method_call(method, payload) do
    dbg([:method_call, method])

    GenServer.cast(
      self(),
      {
        :method_call,
        method,
        payload
      }
    )
  end
end
