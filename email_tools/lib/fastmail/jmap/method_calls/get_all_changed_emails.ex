defmodule Fastmail.Jmap.MethodCalls.GetAllChangedEmails do
  def new(account_id, since_state) do
    [
      [
        "Email/changes",
        %{
          accountId: account_id,
          sinceState: since_state
        },
        "changes"
      ],
      [
        "Email/get",
        %{
          accountId: account_id,
          "#ids": %{
            name: "Email/changes",
            path: "/updated",
            resultOf: "changes"
          }
        },
        "get"
      ]
    ]
  end
end
