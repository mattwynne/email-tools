defmodule EmailToolsWeb.RootLive do
  use EmailToolsWeb, :live_view
  alias EmailTools.FastmailClient

  def mount(_params, _session, socket) do
    fastmail = FastmailClient.start_link() |> FastmailClient.connect()

    {
      :ok,
      socket
      |> assign(:fastmail, fastmail)
      |> assign(:last_response, "")
      |> assign(:connected?, false)
      |> assign(:state, State.new())
      |> assign(:status, "...")
    }
  end

  def render(assigns) do
    ~H"""
    <h2><%= @status %></h2>
    <h1>State:</h1>
    <pre>
    <code>
    <%= inspect(@state, pretty: true) %>
    </code>
    </pre>

    <h1>Last response:</h1>
    <pre>
    <code>
    <%= @last_response %>
    </code>
    </pre>

    <pre><code class="language-json">
    {
    "name": "Phoenix",
    "language": "Elixir"
    }
    </code></pre>

    <pre><code class="json">
    {
    "name": "Phoenix",
    "language": "Elixir"
    }
    </code></pre>
    """
  end

  def handle_info({:response, %{status: 200} = response}, socket) do
    {
      :noreply,
      socket
      |> assign(last_response: inspect(response.body, pretty: true))
    }
  end

  def handle_info({:response, response}, socket) do
    {
      :noreply,
      socket
      |> assign(last_response: response)
    }
  end

  def handle_info({:state, state}, socket) do
    {
      :noreply,
      socket
      |> assign(state: state)
      |> assign(connected?: State.connected?(state))
      |> assign(status: state.status)
    }
  end
end
