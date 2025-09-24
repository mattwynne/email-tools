defmodule Fastmail.Jmap.MethodCalls.GetAllMailboxes do
  defmodule Params do
    defstruct [:account_id]
  end

  def new(%Params{} = %{account_id: account_id}) do
    [
      [
        "Mailbox/get",
        %{
          accountId: account_id,
          ids: nil
        },
        "mailboxes"
      ]
    ]
  end
end