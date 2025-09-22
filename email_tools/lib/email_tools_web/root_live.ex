defmodule EmailToolsWeb.RootLive do
  alias EmailTools.State
  use EmailToolsWeb, :live_view
  alias EmailTools.FastmailClientManager

  on_mount {EmailToolsWeb.UserAuth, :ensure_authenticated}
  on_mount {EmailToolsWeb.UserAuth, :ensure_fastmail_api_key}

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    # Subscribe to updates from the user's FastmailAccount
    Phoenix.PubSub.subscribe(EmailTools.PubSub, "fastmail_client:#{current_user.id}")

    # Get the FastmailAccount for this user (should already be running)
    account_pid = FastmailClientManager.get_client_pid(current_user.id)

    # Get initial state from the account
    initial_account_state = EmailTools.FastmailAccount.get_state(account_pid)

    {
      :ok,
      socket
      |> assign(:fastmail_account_pid, account_pid)
      |> assign(:connected?, State.connected?(initial_account_state))
      |> assign(:state, initial_account_state)
      |> assign(:mailboxes, initial_account_state.mailboxes)
      |> assign(:emails_by_mailbox, initial_account_state.emails_by_mailbox)
    }
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 :if={@connected?}>Connected</h1>
    <h1 :if={!@connected?}>Not Connected</h1>
    <ul :if={@mailboxes}>
      <%= for mailbox <- @mailboxes["list"] do %>
        <li>
          <%= mailbox["name"] %>
          <span :if={@emails_by_mailbox[mailbox["id"]]}>
            (<%= Enum.count(@emails_by_mailbox[mailbox["id"]]) %>)
          </span>
        </li>
      <% end %>
    </ul>
    <hr />
    <h1 class="text-2xl">State:</h1>
    <pre>
    <code>
    <%= inspect(Map.take(@state, [:mailboxes]), pretty: true) %>
    </code>
    </pre>
    """
  end

  def handle_info({:state, state}, socket) do
    # TODO: consider creating a separate ViewState model that the fastmail client emits. Need to keep the token more secret.
    {
      :noreply,
      socket
      |> assign(state: state)
      |> assign(connected?: State.connected?(state))
      |> assign(mailboxes: state.mailboxes)
      |> assign(emails_by_mailbox: state.emails_by_mailbox)
    }
  end
end
