defmodule Fastmail.Jmap do
  defmodule AccountState do
    defstruct [:emails, :mailboxes, :threads, :mailbox_emails]
  end

  defmodule Mailbox do
    defstruct [:id, :name]

    def merge(mailbox, updated_mailbox) do
      Map.merge(mailbox, updated_mailbox)
    end
  end

  defmodule Thread do
    defstruct [:id, :email_ids]

    def merge(thread, updated_thread) do
      Map.merge(thread, updated_thread)
    end
  end

  defmodule Email do
    defstruct [:id, :from, :mailbox_ids, :thread_id]

    # TODO: this can be where we emit pubsub events about specific changes e.g. EmailAddedToMailbox
    def merge(email, updated_email) do
      Map.merge(email, updated_email)
    end
  end

  defmodule Contact do
    defstruct [:email, :name]
  end
end
