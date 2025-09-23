defmodule EmailTools.State do
  alias EmailTools.Mailbox
  alias EmailTools.Email

  defstruct [:mailboxes, :emails_by_mailbox]

  def to_event(%__MODULE__{} = state) do
    {:state, state}
  end

  def new() do
    %__MODULE__{
      mailboxes: %{},
      emails_by_mailbox: %{}
    }
  end

  def changes(%__MODULE__{} = state, email) do
    email_id = email |> Email.id()
    old_mailbox_ids = state |> mailbox_ids_for(email_id) |> MapSet.new()
    new_mailbox_ids = email |> Email.mailbox_ids() |> MapSet.new()
    removed = MapSet.difference(old_mailbox_ids, new_mailbox_ids) |> MapSet.to_list()
    added = MapSet.difference(new_mailbox_ids, old_mailbox_ids) |> MapSet.to_list()
    {added, removed}
  end

  # TODO: test me
  def with_mailboxes(%__MODULE__{} = state, mailboxes) do
    Map.put(state, :mailboxes, mailboxes)
  end

  # TODO: test me
  def set_emails_for_mailbox(%__MODULE__{} = state, mailbox, emails) do
    Map.put(
      state,
      :emails_by_mailbox,
      Map.put(state.emails_by_mailbox, mailbox, emails)
    )
  end

  def mailbox_ids_for(%__MODULE__{} = state, email_id) do
    state
    |> mailbox_ids()
    |> Enum.filter(&contains_email?(state, &1, email_id))
  end

  def remove_from_mailbox(%__MODULE__{} = state, mailbox_id, email_id) do
    update_emails_by_mailbox(
      state,
      mailbox_id,
      Enum.filter(
        state.emails_by_mailbox[mailbox_id],
        &(&1 != email_id)
      )
    )
  end

  def add_to_mailbox(%__MODULE__{} = state, mailbox_id, email_id) do
    update_emails_by_mailbox(
      state,
      mailbox_id,
      state.emails_by_mailbox[mailbox_id] ++ [email_id]
    )
  end

  defp update_emails_by_mailbox(%__MODULE__{} = state, mailbox_id, email_ids) do
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

  defp mailbox_ids(%__MODULE__{} = state) do
    state.emails_by_mailbox
    |> Map.keys()
  end

  defp contains_email?(%__MODULE__{} = state, mailbox_id, email_id) do
    Enum.member?(state.emails_by_mailbox[mailbox_id], email_id)
  end

  def mailbox(%__MODULE__{} = state, id) do
    Enum.find(state.mailboxes["list"], &(Mailbox.id(&1) == id))
  end
end
