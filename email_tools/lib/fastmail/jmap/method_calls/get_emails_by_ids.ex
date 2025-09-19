defmodule Fastmail.Jmap.MethodCalls.GetEmailsByIds do
  def new(account_id, ids) do
    [
      [
        "Email/get",
        %{
          accountId: account_id,
          ids: ids
        },
        "emails"
      ]
    ]
  end
end
