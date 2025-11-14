defmodule InboxCoach.Stats do
  alias Fastmail.Jmap.AccountState

  def count_emails_not_in_archive(%AccountState{
        mailboxes: mailboxes,
        mailbox_emails: mailbox_emails
      }) do
    excluded_mailbox_ids = find_excluded_mailbox_ids(mailboxes)

    excluded_emails =
      excluded_mailbox_ids
      |> Enum.flat_map(fn mailbox_id ->
        Map.get(mailbox_emails || %{}, mailbox_id, [])
      end)
      |> MapSet.new()

    (mailbox_emails || %{})
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reject(fn email_id -> MapSet.member?(excluded_emails, email_id) end)
    |> Enum.count()
  end

  defp find_excluded_mailbox_ids(nil), do: []

  defp find_excluded_mailbox_ids(mailboxes) do
    mailboxes.list
    |> Enum.filter(fn mailbox -> mailbox.role in [:archive, :junk, :sent, :trash] end)
    |> Enum.map(fn mailbox -> mailbox.id end)
  end
end
