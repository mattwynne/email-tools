defmodule EmailTools.State do
  alias EmailTools.Mailbox
  alias EmailTools.Email

  def new(state \\ %{}) do
    state
  end

  def connected?(state) do
    Map.has_key?(state, :session)
  end

  def changes(state, email) do
    email_id = email |> Email.id()
    old_mailbox_ids = state |> mailbox_ids_for(email_id) |> MapSet.new()
    new_mailbox_ids = email |> Email.mailbox_ids() |> MapSet.new()
    removed = MapSet.difference(old_mailbox_ids, new_mailbox_ids) |> MapSet.to_list()
    added = MapSet.difference(new_mailbox_ids, old_mailbox_ids) |> MapSet.to_list()
    {added, removed}
  end

  def mailbox_ids_for(state, email_id) do
    state
    |> mailbox_ids()
    |> Enum.filter(&contains_email?(state, &1, email_id))
  end

  def remove_from_mailbox(state, mailbox_id, email_id) do
    update_emails_by_mailbox(
      state,
      mailbox_id,
      Enum.filter(
        state.emails_by_mailbox[mailbox_id],
        &(&1 != email_id)
      )
    )
  end

  def add_to_mailbox(state, mailbox_id, email_id) do
    update_emails_by_mailbox(
      state,
      mailbox_id,
      state.emails_by_mailbox[mailbox_id] ++ [email_id]
    )
  end

  defp update_emails_by_mailbox(state, mailbox_id, email_ids) do
    Map.put(
      state,
      :emails_by_mailbox,
      Map.put(
        state.emails_by_mailbox,
        mailbox_id,
        email_ids
      )
    )
  end

  defp mailbox_ids(state) do
    state.emails_by_mailbox
    |> Map.keys()
  end

  defp contains_email?(state, mailbox_id, email_id) do
    Enum.member?(state.emails_by_mailbox[mailbox_id], email_id)
  end

  def mailbox(state, id) do
    Enum.find(state.mailboxes["list"], &(Mailbox.id(&1) == id))
  end
end
