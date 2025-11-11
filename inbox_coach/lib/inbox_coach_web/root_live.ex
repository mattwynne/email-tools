defmodule InboxCoachWeb.RootLive do
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

    initial_account_state =
      FastmailAccounts.get_account_pid(current_user.id)
      |> FastmailAccount.get_state()

    {
      :ok,
      socket
      |> assign(:state, initial_account_state)
      |> assign(:mailboxes, initial_account_state.mailboxes)
      |> assign(:mailbox_emails, initial_account_state.mailbox_emails)
      |> assign(:event_stream, [])
      |> assign(:included_mailbox_ids, MapSet.new())
      |> assign(:excluded_mailbox_ids, MapSet.new())
    }
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <header class="bg-gray-800 after:pointer-events-none after:absolute after:inset-x-0 after:inset-y-0 after:border-y after:border-white/10">
      <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <h1 class="text-3xl font-bold text-white">
          You have <%= total_emails(@mailbox_emails) %> emails spread across <%= Enum.count(
            @mailboxes
          ) %> mailboxes.
        </h1>
        <p>
          Let's break that down. Select a mailbox to get started.
        </p>
      </div>
    </header>
    <div class="flex h-screen">
      <div></div>
      <!-- Left Sidebar: Mailboxes -->
      <aside class="w-64 bg-zinc-50 dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800 overflow-y-auto">
        <div class="p-4">
          <h2 class="text-lg font-bold mb-3 text-zinc-900 dark:text-zinc-100">Mailboxes</h2>

          <ul :if={@mailboxes} class="space-y-1">
            <%= for mailbox <- Enum.sort_by(@mailboxes, & &1.name) do %>
              <.mailbox_item
                mailbox={mailbox}
                is_included={MapSet.member?(@included_mailbox_ids, mailbox.id)}
                is_excluded={MapSet.member?(@excluded_mailbox_ids, mailbox.id)}
                email_count={
                  @mailbox_emails && @mailbox_emails[mailbox.id] &&
                    Enum.count(@mailbox_emails[mailbox.id])
                }
              />
            <% end %>
          </ul>
        </div>
      </aside>
      <!-- Right Content Area: Selected Emails -->
      <main class="flex-1 overflow-y-auto">
        <div class="p-6">
          <div :if={not Enum.empty?(@included_mailbox_ids)}>
            <h1 class="text-2xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">
              Selected Mailboxes
            </h1>

            <% selected_emails =
              get_selected_emails(@included_mailbox_ids, @excluded_mailbox_ids, @mailbox_emails) %>

            <div>
              Showing emails in <%= query_summary(
                @included_mailbox_ids,
                @excluded_mailbox_ids,
                @mailboxes
              ) %>
            </div>

            <div
              id="selected-email-count"
              class="mb-4 text-sm font-semibold text-zinc-700 dark:text-zinc-300"
            >
              Total emails: <%= Enum.count(selected_emails) %>
            </div>
            <div class="border-t border-zinc-300 dark:border-zinc-700 mb-3"></div>

            <div class="mt-6">
              <h3 class="text-sm font-semibold mb-2 text-zinc-700 dark:text-zinc-300">Mailboxes:</h3>
              <ul id="mailbox-summary" class="space-y-1">
                <%= for {mailbox, count} <- get_mailbox_summary(selected_emails, @mailbox_emails, @mailboxes, @excluded_mailbox_ids) do %>
                  <.mailbox_item
                    scope="summary"
                    mailbox={mailbox}
                    is_included={MapSet.member?(@included_mailbox_ids, mailbox.id)}
                    is_excluded={MapSet.member?(@excluded_mailbox_ids, mailbox.id)}
                    email_count={count}
                  />
                <% end %>
              </ul>
            </div>
          </div>

          <div :if={Enum.empty?(@included_mailbox_ids)} class="text-center py-12">
            <p class="text-zinc-500 dark:text-zinc-400">
              Select mailboxes from the sidebar
            </p>
          </div>

          <div
            :if={not Enum.empty?(@event_stream)}
            class="mt-8 pt-8 border-t border-zinc-200 dark:border-zinc-800"
          >
            <h2 class="text-xl font-bold mb-4 text-zinc-900 dark:text-zinc-100">Stream</h2>
            <ul class="space-y-2">
              <%= for event <- @event_stream do %>
                <li class="text-sm text-zinc-600 dark:text-zinc-400">
                  <%= format_event(event, @state) %>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp mailbox_item(assigns) do
    # Default scope to "sidebar" if not provided
    assigns = Map.put_new(assigns, :scope, "sidebar")

    state_class =
      cond do
        assigns.is_included ->
          "border bg-green-100 dark:bg-green-900/30 border-green-500 dark:border-green-700"

        assigns.is_excluded ->
          "border bg-red-100 dark:bg-red-900/30 border-red-500 dark:border-red-700"

        true ->
          "border-transparent "
      end

    assigns = assign(assigns, :state_class, state_class)

    ~H"""
    <li
      id={"#{@scope}-mailbox-#{@mailbox.id}"}
      phx-click="toggle_mailbox"
      phx-value-mailbox-id={@mailbox.id}
      class={"flex items-center justify-between gap-2 dark:hover:bg-zinc-800 p-1 m-0 border rounded #{@state_class}"}
    >
      <Heroicons.icon name={mailbox_icon(@mailbox.role)} type="outline" class="h-4 w-4" />
      <div class="flex items-center gap-2 cursor-pointer flex-1">
        <span class="text-sm text-zinc-900 dark:text-zinc-100">
          <%= @mailbox.name %>
        </span>
      </div>
      <span :if={@email_count} class="text-xs text-zinc-500 dark:text-zinc-100">
        <%= @email_count %>
      </span>
      <button
        id={"#{@scope}-mailbox-#{@mailbox.id}-exclude"}
        phx-click="exclude_mailbox"
        phx-value-mailbox-id={@mailbox.id}
        class="text-xs px-2 py-1 rounded bg-zinc-200 dark:bg-zinc-700 hover:bg-red-200 dark:hover:bg-red-900 text-zinc-700 dark:text-zinc-300"
        title="Exclude this mailbox"
      >
        ✗
      </button>
    </li>
    """
  end

  defp mailbox_icon(:none), do: "tag"
  defp mailbox_icon(:sent), do: "paper-airplane"
  defp mailbox_icon(:trash), do: "trash"
  defp mailbox_icon(:drafts), do: "pencil-square"
  defp mailbox_icon(:inbox), do: "inbox"
  defp mailbox_icon(:junk), do: "x-circle"
  defp mailbox_icon(_), do: "archive-box"

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

  defp get_selected_emails(included_mailbox_ids, excluded_mailbox_ids, mailbox_emails) do
    # Get intersection of all included mailboxes (AND logic)
    included_emails =
      included_mailbox_ids
      |> Enum.map(fn mailbox_id ->
        mailbox_emails
        |> Map.get(mailbox_id, [])
        |> MapSet.new()
      end)
      |> case do
        [] -> MapSet.new()
        [first | rest] -> Enum.reduce(rest, first, &MapSet.intersection/2)
      end

    # Get union of all excluded mailboxes (emails to remove)
    excluded_emails =
      excluded_mailbox_ids
      |> Enum.flat_map(fn mailbox_id ->
        Map.get(mailbox_emails, mailbox_id, [])
      end)
      |> MapSet.new()

    # Remove excluded emails from included emails
    MapSet.difference(included_emails, excluded_emails)
    |> MapSet.to_list()
  end

  defp get_mailbox_summary(selected_emails, mailbox_emails, mailboxes, excluded_mailbox_ids) do
    selected_email_set = MapSet.new(selected_emails)

    # For each mailbox, count how many of the selected emails it contains
    mailbox_emails
    |> Enum.map(fn {mailbox_id, email_ids} ->
      mailbox_email_set = MapSet.new(email_ids)
      count = MapSet.intersection(selected_email_set, mailbox_email_set) |> MapSet.size()
      {mailbox_id, count}
    end)
    # Show mailboxes with count > 0 OR that are excluded (part of active query)
    |> Enum.filter(fn {mailbox_id, count} ->
      count > 0 or MapSet.member?(excluded_mailbox_ids, mailbox_id)
    end)
    |> Enum.map(fn {mailbox_id, count} ->
      mailbox = Fastmail.Jmap.Collection.get(mailboxes, mailbox_id)
      {mailbox, count}
    end)
    |> Enum.sort_by(fn {mailbox, _count} -> mailbox.name end)
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
    included = socket.assigns.included_mailbox_ids
    excluded = socket.assigns.excluded_mailbox_ids

    {new_included, new_excluded} =
      if MapSet.member?(included, mailbox_id) or MapSet.member?(excluded, mailbox_id) do
        # If active (included or excluded), remove from both
        {MapSet.delete(included, mailbox_id), MapSet.delete(excluded, mailbox_id)}
      else
        # If inactive, add to included
        {MapSet.put(included, mailbox_id), excluded}
      end

    {:noreply,
     socket
     |> assign(:included_mailbox_ids, new_included)
     |> assign(:excluded_mailbox_ids, new_excluded)}
  end

  def handle_event("exclude_mailbox", %{"mailbox-id" => mailbox_id}, socket) do
    included = socket.assigns.included_mailbox_ids
    excluded = socket.assigns.excluded_mailbox_ids

    # Remove from included (if present) and add to excluded
    new_included = MapSet.delete(included, mailbox_id)
    new_excluded = MapSet.put(excluded, mailbox_id)

    {:noreply,
     socket
     |> assign(:included_mailbox_ids, new_included)
     |> assign(:excluded_mailbox_ids, new_excluded)}
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
    event_with_type = Map.put(event, :type, :email_removed_from_mailbox)

    {
      :noreply,
      socket
      |> assign(:event_stream, [event_with_type | socket.assigns.event_stream])
    }
  end

  defp query_summary(included_mailbox_ids, excluded_mailbox_ids, mailboxes) do
    included = included_mailbox_ids |> Enum.map(fn id -> get_mailbox_name(mailboxes, id) end)
    excluded = excluded_mailbox_ids |> Enum.map(fn id -> get_mailbox_name(mailboxes, id) end)
    [Enum.join(included, " AND ") | excluded] |> Enum.join(" NOT ")
  end

  defp total_emails(mailbox_emails) do
    Map.values(mailbox_emails)
    |> Enum.flat_map(&Function.identity/1)
    |> MapSet.new()
    |> Enum.count()
  end
end
