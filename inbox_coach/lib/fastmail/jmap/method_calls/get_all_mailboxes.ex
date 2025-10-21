defmodule Fastmail.Jmap.MethodCalls.GetAllMailboxes do
  alias InboxCoach.State

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

    # TODO: the state needs to be something closer to us here, we shouldn't know about InboxCoach, maybe a Jmap.Collection? and be a struct
    # TODO: test this once we have a better State to work with
    def apply_to(%__MODULE__{} = response, %State{} = state) do
      State.with_mailboxes(
        state,
        %{
          "list" =>
            response.mailboxes
            |> Enum.map(fn mailbox ->
              %{"id" => mailbox.id, "name" => mailbox.name}
            end)
        }
      )
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
