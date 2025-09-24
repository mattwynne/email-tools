defmodule Fastmail.Jmap.MethodCalls.QueryAllEmails do
  defmodule Params do
    defstruct [:account_id, :in_mailbox]
  end

  def new(account_id, in_mailbox) do
    new(%Params{account_id: account_id, in_mailbox: in_mailbox})
  end

  def new(%Params{} = %{account_id: account_id, in_mailbox: in_mailbox}) do
    [
      [
        "Email/query",
        %{
          accountId: account_id,
          filter: %{
            inMailbox: in_mailbox
          }
        },
        "query"
      ]
    ]
  end
end
