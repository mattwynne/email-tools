defmodule InboxCoachWeb.StateLive do
  require Logger
  use InboxCoachWeb, :live_view
  alias InboxCoach.{FastmailAccounts, FastmailAccount}

  on_mount {InboxCoachWeb.UserAuth, :ensure_authenticated}
  on_mount {InboxCoachWeb.UserAuth, :ensure_fastmail_api_key}

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    Phoenix.PubSub.subscribe(
      InboxCoach.PubSub,
      FastmailAccount.pubsub_topic_for(current_user)
    )

    state =
      FastmailAccounts.get_account_pid(current_user.id)
      |> FastmailAccount.get_state()

    {
      :ok,
      socket
      |> assign(:state, state)
    }
  end

  def render(assigns) do
    ~H"""
    <%= inspect(@state, pretty: true, syntax_colors: IO.ANSI.syntax_colors()) |> AnsiToHTML.generate_phoenix_html(theme()) %>
    """
  end

  defp theme() do
    AnsiToHTML.Theme.new(
      container:
        {:pre,
         [
           style: "font-mono bg-gray-900 text-white p-4 rounded"
         ]}
    )
  end

  def handle_info({:state, state}, socket) do
    {
      :noreply,
      socket
      |> assign(state: state)
    }
  end
end
