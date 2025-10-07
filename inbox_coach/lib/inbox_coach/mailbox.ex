defmodule InboxCoach.Mailbox do
  defstruct [:id, :name]

  def new(mailbox) do
    %__MODULE__{
      id: mailbox["id"],
      name: mailbox["name"]
    }
  end

  def name(mailbox) do
    mailbox["name"]
  end
end
