defmodule Fastmail.Jmap.MethodCalls.QueryAllEmails do
  defmodule Params do
    defstruct [:account_id, :in_mailbox]
  end

  defmodule Response do
    alias Fastmail.Jmap.AccountState
    defstruct [:mailbox_id, :email_ids]

    def new([["Email/query", body, _]]) do
      %__MODULE__{
        mailbox_id: body["filter"]["inMailbox"],
        email_ids: body["ids"]
      }
    end

    def apply_to(
          %__MODULE__{} = %{mailbox_id: mailbox_id, email_ids: email_ids},
          %AccountState{mailbox_emails: mailbox_emails} = account_state
        ) do
      mailbox_emails =
        (mailbox_emails || %{})
        |> Map.put(mailbox_id, email_ids)

      %{account_state | mailbox_emails: mailbox_emails}
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
