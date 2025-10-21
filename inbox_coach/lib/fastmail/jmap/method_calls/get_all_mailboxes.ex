defmodule Fastmail.Jmap.MethodCalls.GetAllMailboxes do
  defmodule Params do
    defstruct [:account_id]
  end

  defmodule Response do
    alias Fastmail.Jmap.AccountState
    alias Fastmail.Jmap.Collection
    alias Fastmail.Jmap.Mailbox
    defstruct [:mailboxes]

    def new([["Mailbox/get", body, _]]) do
      mailboxes =
        body["list"]
        |> Enum.map(fn mailbox ->
          %Mailbox{
            name: mailbox["name"],
            id: mailbox["id"]
          }
        end)

      %__MODULE__{
        mailboxes: Collection.new(body["state"], mailboxes)
      }
    end

    def apply_to(%__MODULE__{mailboxes: mailboxes}, %AccountState{} = account_state) do
      %{account_state | mailboxes: mailboxes}
    end
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
