defmodule Fastmail.Jmap.MethodCalls.GetAllChanged do
  defmodule Params do
    defstruct [:account_id, :type, :since_state]
  end

  defmodule Response do
    alias Fastmail.Jmap.AccountState
    alias Fastmail.Jmap.Email
    alias Fastmail.Jmap.Contact
    alias Fastmail.Jmap.Collection
    alias Fastmail.Jmap.Mailbox
    alias Fastmail.Jmap.Thread

    defstruct [:type, :old_state, :updated]

    def new([
          ["Email/changes", %{"oldState" => old_state}, _],
          ["Email/get", %{"state" => state, "list" => emails}, "updated"]
        ]) do
      updated =
        Enum.map(emails, fn email ->
          %Email{
            id: email["id"],
            thread_id: email["threadId"],
            mailbox_ids:
              email["mailboxIds"]
              |> Enum.filter(fn {_, yeah?} -> yeah? end)
              |> Enum.map(fn {id, _} -> id end),
            from:
              email["from"]
              |> Enum.map(fn sender ->
                %Contact{
                  email: sender["email"],
                  name: sender["name"]
                }
              end)
          }
        end)

      %__MODULE__{
        type: :email,
        old_state: old_state,
        updated: Collection.new(state, updated)
      }
    end

    def new([
          ["Mailbox/changes", %{"oldState" => old_state, "newState" => _new_state}, _],
          ["Mailbox/get", %{"state" => state, "list" => updated}, "updated"]
        ]) do
      updated =
        Enum.map(updated, fn mailbox ->
          %Mailbox{
            id: mailbox["id"],
            name: mailbox["name"]
          }
        end)

      %__MODULE__{
        type: :mailbox,
        old_state: old_state,
        updated: Collection.new(state, updated)
      }
    end

    def new([
          ["Thread/changes", %{"oldState" => old_state}, _],
          ["Thread/get", %{"state" => state, "list" => updated}, "updated"]
        ]) do
      updated =
        Enum.map(updated, fn thread ->
          %Thread{
            id: thread["id"],
            email_ids: thread["emailIds"]
          }
        end)

      %__MODULE__{
        type: :thread,
        old_state: old_state,
        updated: Collection.new(state, updated)
      }
    end

    def apply_to(
          %__MODULE__{old_state: old_state, type: :email, updated: updated},
          %AccountState{emails: %{state: old_state}} = account_state
        ) do
      emails = Collection.update(account_state.emails, updated)
      %{account_state | emails: emails}
    end

    def apply_to(
          %__MODULE__{old_state: old_state, type: :mailbox, updated: updated},
          %AccountState{mailboxes: %{state: old_state}} = account_state
        ) do
      mailboxes = Collection.update(account_state.mailboxes, updated)
      %{account_state | mailboxes: mailboxes}
    end

    def apply_to(
          %__MODULE__{old_state: old_state, type: :thread, updated: updated},
          %AccountState{threads: %{state: old_state}} = account_state
        ) do
      threads = Collection.update(account_state.threads, updated)
      %{account_state | threads: threads}
    end
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
        "updated"
      ]
    ]
  end
end
