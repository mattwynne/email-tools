defmodule EmailToolsWeb.RootLive do
  alias EmailTools.State
  use EmailToolsWeb, :live_view
  alias EmailTools.FastmailClient

  on_mount {EmailToolsWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    fastmail = FastmailClient.start_link(user: current_user) |> FastmailClient.connect()

    {
      :ok,
      socket
      |> assign(:fastmail, fastmail)
      |> assign(:connected?, false)
      |> assign(:state, State.new())
      |> assign(:mailboxes, nil)
      |> assign(:emails_by_mailbox, %{})
    }
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1>test</h1>
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
    <%= inspect(@state, pretty: true) %>
    </code>
    </pre>
    """
  end

  def handle_info({:state, state}, socket) do
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
