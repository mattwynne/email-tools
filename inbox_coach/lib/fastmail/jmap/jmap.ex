defmodule Fastmail.Jmap do

  defmodule AccountState do
    defstruct [:emails, :mailboxes, :threads, :mailbox_emails]
  end

  defmodule Mailbox do
    require Logger
    defstruct [:id, :name, :role]

    def from_jmap(%{} = data) do
      %__MODULE__{
        id: data["id"],
        name: data["name"],
        role: role(data["role"])
      }
    end

    def merge(mailbox, updated_mailbox) do
      Map.merge(mailbox, updated_mailbox)
    end

    defp role(role) when role in ["inbox", "archive", "drafts", "sent", "junk", "trash"] do
      String.to_atom(role)
    end

    defp role(nil), do: :none

    defp role(role) do
      Logger.warning("Unknown mailbox role encountered: #{inspect(role)}")
      :none
    end
  end

  defmodule Thread do
    defstruct [:id, :email_ids]

    def merge(thread, updated_thread) do
      Map.merge(thread, updated_thread)
    end
  end

  defmodule Email do
    defstruct [:id, :from, :mailbox_ids, :thread_id, :subject]

    def merge(email, updated_email) do
      Map.merge(email, updated_email)
    end
  end

  defmodule Contact do
    defstruct [:email, :name]
  end
end
