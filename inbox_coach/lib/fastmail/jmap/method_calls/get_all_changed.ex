defmodule Fastmail.Jmap.MethodCalls.GetAllChanged do
  defmodule Params do
    defstruct [:account_id, :type, :since_state]
  end

  def new(%Params{} = %{account_id: account_id, type: type, since_state: since_state}) do
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
