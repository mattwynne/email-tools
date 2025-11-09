defmodule InboxCoachWeb.RootLive do
  use InboxCoachWeb, :live_view
  alias InboxCoach.{FastmailAccounts, FastmailAccount, Stats}

  on_mount {InboxCoachWeb.UserAuth, :ensure_authenticated}
  on_mount {InboxCoachWeb.UserAuth, :ensure_fastmail_api_key}

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    Phoenix.PubSub.subscribe(
      InboxCoach.PubSub,
      FastmailAccount.pubsub_topic_for(current_user)
    )

    initial_account_state =
      FastmailAccounts.get_account_pid(current_user.id)
      |> FastmailAccount.get_state()

    {
      :ok,
      socket
      |> assign(:state, initial_account_state)
      |> assign(:mailboxes, initial_account_state.mailboxes)
      |> assign(:emails_by_mailbox, initial_account_state.mailbox_emails)
      |> assign(:event_stream, [])
      |> assign(:selected_mailbox_ids, MapSet.new())
    }
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id="live-email-count" :if={@state.mailboxes && @state.mailbox_emails}>
      Live emails: <%= Stats.count_emails_not_in_archive(@state) %>
    </div>
    <ul :if={@mailboxes}>
      <%= for mailbox <- @mailboxes do %>
        <li>
          <label for={"mailbox-#{mailbox.id}"}>
            <input
              type="checkbox"
              id={"mailbox-#{mailbox.id}"}
              phx-click="toggle_mailbox"
              phx-value-mailbox-id={mailbox.id}
              checked={MapSet.member?(@selected_mailbox_ids, mailbox.id)}
            />
            <%= mailbox.name %>
          </label>
          <span :if={@emails_by_mailbox && @emails_by_mailbox[mailbox.id]}>
            (<%= Enum.count(@emails_by_mailbox[mailbox.id]) %>)
          </span>
        </li>
      <% end %>
    </ul>
    <hr />
    <div :if={not Enum.empty?(@selected_mailbox_ids)}>
      <h2 class="text-xl">Selected Mailboxes</h2>
      <% selected_emails = get_selected_emails(@selected_mailbox_ids, @emails_by_mailbox) %>
      <div id="selected-email-count">
        Total emails: <%= Enum.count(selected_emails) %>
      </div>
      <ul id="selected-email-list">
        <%= for email_id <- selected_emails do %>
          <li><%= email_id %></li>
        <% end %>
      </ul>
    </div>
    <hr />
    <h1 class="text-2xl">Stream:</h1>
    <ul>
      <%= for event <- @event_stream do %>
        <li><%= format_event(event, @state) %></li>
      <% end %>
    </ul>
    <hr />
    <h1 class="text-2xl">State:</h1>
    <pre>
    <code>
    <%= inspect(Map.take(@state, [:mailboxes, :mailbox_emails, :emails]), pretty: true) %>
    </code>
    </pre>
    """
  end

  defp format_event(
         %{
           type: :email_added_to_mailbox,
           email_id: email_id,
           mailbox_id: mailbox_id,
           old_state: old_state,
           new_state: new_state
         },
         state
       ) do
    mailbox_name = get_mailbox_name(state.mailboxes, mailbox_id)
    email_subject = get_email_subject(state.emails, email_id)
    "#{email_subject} added to #{mailbox_name} from #{old_state} to #{new_state}"
  end

  defp format_event(
         %{
           type: :email_added_to_mailbox,
           email_id: email_id,
           mailbox_id: mailbox_id
         },
         state
       ) do
    mailbox_name = get_mailbox_name(state.mailboxes, mailbox_id)
    email_subject = get_email_subject(state.emails, email_id)
    "#{email_subject} added to #{mailbox_name}"
  end

  defp format_event(
         %{
           type: :email_removed_from_mailbox,
           email_id: email_id,
           mailbox_id: mailbox_id,
           old_state: old_state,
           new_state: new_state
         },
         state
       ) do
    mailbox_name = get_mailbox_name(state.mailboxes, mailbox_id)
    email_subject = get_email_subject(state.emails, email_id)
    "#{email_subject} removed from #{mailbox_name} from #{old_state} to #{new_state}"
  end

  defp get_selected_emails(selected_mailbox_ids, emails_by_mailbox) do
    selected_mailbox_ids
    |> Enum.flat_map(fn mailbox_id ->
      Map.get(emails_by_mailbox, mailbox_id, [])
    end)
    |> Enum.uniq()
  end

  defp get_mailbox_name(nil, mailbox_id), do: mailbox_id

  defp get_mailbox_name(mailboxes, mailbox_id) do
    case Fastmail.Jmap.Collection.get(mailboxes, mailbox_id) do
      nil -> mailbox_id
      mailbox -> mailbox.name
    end
  end

  defp get_email_subject(nil, email_id), do: email_id

  defp get_email_subject(emails, email_id) do
    case Fastmail.Jmap.Collection.get(emails, email_id) do
      nil -> email_id
      email -> email.subject || email.id
    end
  end

  def handle_event("toggle_mailbox", %{"mailbox-id" => mailbox_id}, socket) do
    selected_mailbox_ids = socket.assigns.selected_mailbox_ids

    updated_selection =
      if MapSet.member?(selected_mailbox_ids, mailbox_id) do
        MapSet.delete(selected_mailbox_ids, mailbox_id)
      else
        MapSet.put(selected_mailbox_ids, mailbox_id)
      end

    {:noreply, assign(socket, :selected_mailbox_ids, updated_selection)}
  end

  def handle_info({:state, state}, socket) do
    {
      :noreply,
      socket
      |> assign(state: state)
      |> assign(mailboxes: state.mailboxes)
      |> assign(emails_by_mailbox: state.mailbox_emails)
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
    event_with_type = Map.put(event, :type, :email_removed_from_mailbox)

    {
      :noreply,
      socket
      |> assign(:event_stream, [event_with_type | socket.assigns.event_stream])
    }
  end
end
