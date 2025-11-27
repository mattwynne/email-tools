defmodule InboxCoachWeb.EventsLive do
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
      case FastmailAccounts.get_account_pid(current_user.id) do
        nil -> %Fastmail.Jmap.AccountState{}
        pid -> FastmailAccount.get_state(pid)
      end

    {
      :ok,
      socket
      |> assign(:state, state)
      |> assign(:mailboxes, state.mailboxes)
      |> assign(:mailbox_emails, state.mailbox_emails)
      |> assign(:event_stream, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div
      :if={not Enum.empty?(@event_stream)}
      class="mt-8 pt-8 border-t border-zinc-200 dark:border-zinc-800"
    >
      <h2 class="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">Stream</h2>
      <ul class="space-y-2">
        <%= for event <- @event_stream do %>
          <li class="text-sm text-zinc-600 dark:text-zinc-400">
            <.event event={enrich(event, @state)} />
          </li>
        <% end %>
      </ul>
    </div>
    <div :if={Enum.empty?(@event_stream)}>
      Waiting for events...
    </div>
    """
  end

  defp get_mailbox_name(nil, mailbox_id), do: mailbox_id

  defp get_mailbox_name(mailboxes, mailbox_id) do
    case Fastmail.Jmap.Collection.get(mailboxes, mailbox_id) do
      nil -> mailbox_id
      mailbox -> mailbox.name
    end
  end

  def handle_info({:state, state}, socket) do
    {
      :noreply,
      socket
      |> assign(state: state)
      |> assign(mailboxes: state.mailboxes)
      |> assign(mailbox_emails: state.mailbox_emails)
    }
  end

  def handle_info({:email_added_to_mailbox, event}, socket) do
    event_with_type = Map.put(event, :type, :email_added_to_mailbox)

    {
      :noreply,
      socket
      |> assign(:event_stream, [event_with_type | socket.assigns.event_stream])
    }
  end

  def handle_info({:email_removed_from_mailbox, event}, socket) do
    dbg(event)
    event_with_type = Map.put(event, :type, :email_removed_from_mailbox)

    {
      :noreply,
      socket
      |> assign(:event_stream, [event_with_type | socket.assigns.event_stream])
    }
  end

  defp enrich(event, state) do
    event
    |> Map.put(:mailbox_name, get_mailbox_name(state.mailboxes, event.mailbox_id))
    |> Map.put(:email, Fastmail.Jmap.Collection.get(state.emails, event.email_id))
  end

  defp event(%{event: %{type: :email_added_to_mailbox}} = assigns) do
    ~H"""
    <.email email={@event.email} /> added to <%= @event.mailbox_name %>
    """
  end

  defp event(%{event: %{type: :email_removed_from_mailbox}} = assigns) do
    ~H"""
    <div class="flex flex-row items-start gap-1">
      <.email email={@event.email} /> removed from
      <Heroicons.icon name="tag" type="outline" class="h-4 w-4" /> <%= @event.mailbox_name %>
    </div>
    """
  end

  defp email(assigns) do
    assigns =
      assign(
        assigns,
        :url,
        "https://app.fastmail.com/mail/Archive/" <>
          assigns.email.thread_id <> "." <> assigns.email.id <> "?u=360641ae"
      )

    ~H"""
    <.link
      navigate={@url}
      class="text-sm font-semibold leading-6 dark:text-zinc-100 text-zinc-900 dark:hover:text-zinc-300 hover:text-zinc-700"
    >
      <%= @email.subject %>
    </.link>
    """
  end
end
