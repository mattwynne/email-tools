defmodule Fastmail.Jmap.MethodCalls.GetAllChanged do
  def new(account_id, type, since_state) do
    [
      [
        "#{type}/changes",
        %{
          accountId: account_id,
          sinceState: since_state
        },
        "changes"
      ],
      [
        "#{type}/get",
        %{
          accountId: account_id,
          "#ids": %{
            name: "#{type}/changes",
            path: "/updated",
            resultOf: "changes"
          }
        },
        "get"
      ]
    ]
  end
end
