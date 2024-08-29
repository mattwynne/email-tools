defmodule EmailToolsWeb.RootLive do
  use EmailToolsWeb, :live_view
  alias EmailTools.FastmailClient

  def mount(_params, _session, socket) do
    fastmail = FastmailClient.start_link() |> FastmailClient.connect()

    {
      :ok,
      socket
      |> assign(:fastmail, fastmail)
      |> assign(:connected?, false)
      |> assign(:state, State.new())
      |> assign(:status, "...")
      |> assign(:mailboxes, [])
      |> assign(:emails_by_mailbox, %{})
    }
  end

  def render(assigns) do
    ~H"""
    <ul>
      <%= for mailbox <- @mailboxes do %>
        <li>
          <%= mailbox["name"] %>
          <span :if={@emails_by_mailbox[mailbox["id"]]}>
            (<%= Enum.count(@emails_by_mailbox[mailbox["id"]]) %>)
          </span>
        </li>
      <% end %>
    </ul>
    <h2><%= @status %></h2>
    <h1>State:</h1>
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
      |> assign(status: state.status)
      |> assign(mailboxes: state.mailboxes)
      |> assign(emails_by_mailbox: state.emails_by_mailbox)
    }
  end
end
