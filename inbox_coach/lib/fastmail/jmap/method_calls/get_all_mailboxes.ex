defmodule Fastmail.Jmap.MethodCalls.GetAllMailboxes do
  alias InboxCoach.State

  defmodule Params do
    defstruct [:account_id]
  end

  defmodule Response do
    defstruct [:state, :mailboxes]

    def new([["Mailbox/get", body, _]]) do
      mailboxes =
        body["list"]
        |> Enum.map(fn mailbox_data ->
          %Fastmail.Jmap.Mailbox{
            name: mailbox_data["name"],
            id: mailbox_data["id"]
          }
        end)

      %__MODULE__{
        state: body["state"],
        mailboxes: mailboxes
      }
    end

    # TODO: the state needs to be something closer to us here, we shouldn't know about InboxCoach, maybe a Jmap.Mailboxes? and be a struct
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
