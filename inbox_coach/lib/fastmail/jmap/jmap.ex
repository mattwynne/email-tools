defmodule Fastmail.Jmap do
  defmodule Mailbox do
    defstruct [:id, :name]
  end

  defmodule Thread do
    defstruct [:id, :email_ids]
  end

  defmodule Email do
    defstruct [:id, :from, :mailbox_ids, :thread_id]
  end

  defmodule Contact do
    defstruct [:email, :name]
  end
end
