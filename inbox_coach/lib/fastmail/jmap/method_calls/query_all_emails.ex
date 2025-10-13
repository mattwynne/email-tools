defmodule Fastmail.Jmap.MethodCalls.QueryAllEmails do
  defmodule Params do
    defstruct [:account_id, :in_mailbox]
  end

  defmodule Response do
    defstruct [:mailbox_id, :email_ids]

    def new([["Email/query", body, _]]) do
      %__MODULE__{
        mailbox_id: body["filter"]["inMailbox"],
        email_ids: body["ids"]
      }
    end
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
