defmodule Fastmail.Jmap.MethodCalls.GetEmailsByIds do
  defmodule Params do
    defstruct [:account_id, :ids]
  end

  def new(account_id, ids) do
    new(%Params{account_id: account_id, ids: ids})
  end

  def new(%Params{} = %{account_id: account_id, ids: ids}) do
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
