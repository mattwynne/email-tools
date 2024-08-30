defmodule EmailTools.FastmailClient do
  alias EmailTools.FastmailEvents
  use GenServer

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")

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

    result =
      Req.get(
        "https://api.fastmail.com/jmap/session",
        headers: headers(state)
      )

    state =
      case result do
        {:ok, response} ->
          session = response.body

          state =
            state
            |> Map.put(:session, session)

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
    account_id = State.account_id(state)
    handle_changes(changes, account_id, state)

    state =
      state
      |> Map.put(:latest, changes)

    send(state.ui, {:state, state})
    {:noreply, state}
  end

  def handle_cast({:method_call, method, params}, state) do
    response =
      Req.post!(
        State.api_url(state),
        body:
          Jason.encode!(%{
            using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
            methodCalls: [[method, params, "a"]]
          }),
        headers: headers(state)
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
      method_call(
        "Email/query",
        %{
          accountId: State.account_id(state),
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
      accountId: State.account_id(state),
      ids: ids
    })

    {:noreply, state}
  end

  def handle_info(["Email/get", result, _], state) do
    emails = result["list"]

    for email <- emails do
      email_id = email["id"]
      new_mailbox_ids = Map.keys(email["mailboxIds"])
      dbg([:email_moved, email_id, new_mailbox_ids])
      # TODO: build State.mailboxes_for_email that scans the emails_by_mailbox maps and compares
      # or maybe something that updates the state and emits an event?
    end

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
        state.session["eventSourceUrl"],
        state.token
      )
    )
  end

  defp handle_changes(changes, account_id, %{latest: old_changes} = state) do
    new = changes[account_id]
    old = old_changes[account_id]
    dbg(old)

    ["Email", "Mailbox"]
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
        accountId: State.account_id(state),
        sinceState: since
      }
    )
  end

  defp fetch_initial_state(state) do
    method_call(
      "Mailbox/get",
      %{
        accountId: State.account_id(state),
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

  defp headers(%{token: token}) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]
  end
end
