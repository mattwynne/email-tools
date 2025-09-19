defmodule Fastmail.Jmap.MethodCalls.QueryAllEmails do
  def new(account_id, in_mailbox) do
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
