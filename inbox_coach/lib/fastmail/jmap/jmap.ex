defmodule Fastmail.Jmap do
  defmodule AccountState do
    defstruct [:emails, :mailboxes, :threads]
  end

  defmodule Mailbox do
    defstruct [:id, :name]
  end

  defmodule Thread do
    defstruct [:id, :email_ids]
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
