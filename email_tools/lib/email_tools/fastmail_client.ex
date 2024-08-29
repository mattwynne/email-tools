defmodule EmailTools.FastmailClient do
  alias EmailTools.FastmailEvents
  use GenServer

  def start_link(opts \\ []) do
    token = System.get_env("FASTMAIL_API_TOKEN")

    state = %{
      token: token,
      ui: self(),
      status: "Connecting to Fastmail servers",
      mailboxes: [],
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

    response =
      Req.get!(
        "https://api.fastmail.com/jmap/session",
        headers: headers(state)
      )

    state =
      case response do
        %{status: 200} ->
          session = response.body

          state =
            state
            |> Map.put(:session, session)
            |> Map.put(:status, "Connecting to event stream")

          send(state.ui, {:state, state})

          state
          |> stream_events()
          |> fetch_initial_state()

        _ ->
          state
      end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:event, data}, state) do
    dbg([:client, :event, data])
    changes = data["changes"]
    account_id = State.account_id(state)
    handle_changes(changes, account_id, state)

    state =
      state
      |> Map.put(:latest, changes)
      |> Map.put(:status, "Handling update event")

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
  def handle_info(["Thread/changes", result, _], state) do
    GenServer.cast(
      self(),
      {:method_call, "Thread/get",
       %{
         accountId: State.account_id(state),
         ids: result["updated"]
       }}
    )

    {:noreply, state}
  end

  def handle_info(["Mailbox/get", %{"list" => mailboxes}, _], state) do
    Enum.each(mailboxes, fn mailbox ->
      GenServer.cast(
        self(),
        {:method_call, "Email/query",
         %{
           accountId: State.account_id(state),
           filter: %{
             inMailbox: mailbox["id"]
           }
         }}
      )
    end)

    state = state |> Map.put(:mailboxes, mailboxes)

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

  def handle_info(msg, state) do
    dbg([:unhandled, msg])
    {:noreply, state}
  end

  defp stream_events(state) do
    url = state.session["eventSourceUrl"]
    {:ok, events} = FastmailEvents.start_link(%{url: url, token: state.token, last_event_id: "0"})

    state |> Map.put(:events, events)
  end

  defp handle_changes(changes, account_id, %{latest: old_changes} = state) do
    new = changes[account_id]
    old = old_changes[account_id]
    dbg(old)

    ["Email", "Mailbox", "Thread"]
    |> Enum.each(fn type ->
      if old[type] != new[type] do
        get_changes(type, old[type], state)
      end
    end)
  end

  defp handle_changes(_, _, _), do: nil

  defp get_changes(type, since, state) do
    GenServer.cast(
      self(),
      {
        :method_call,
        "#{type}/changes",
        %{
          accountId: State.account_id(state),
          sinceState: since
        }
      }
    )
  end

  defp fetch_initial_state(state) do
    GenServer.cast(
      self(),
      {:method_call, "Mailbox/get",
       %{
         accountId: State.account_id(state),
         ids: nil
       }}
    )

    state
  end

  defp headers(%{token: token}) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]
  end
end
