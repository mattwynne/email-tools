defmodule Fastmail.Jmap.MethodCalls.GetAllChanged do
  defmodule Params do
    defstruct [:account_id, :type, :since_state]
  end

  defmodule Email do
    defstruct [:id, :from, :mailbox_ids, :thread_id]
  end

  defmodule Contact do
    defstruct [:email, :name]
  end

  defmodule Response do
    alias Fastmail.Jmap.Mailboxes
    alias Fastmail.Jmap.Mailbox
    alias Fastmail.Jmap.Threads
    alias Fastmail.Jmap.Thread
    defstruct [:type, :updated]

    def new([
          ["Email/changes", _, _],
          ["Email/get", %{"list" => emails}, "updated"]
        ]) do
      %__MODULE__{
        type: :email,
        updated:
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
      }
    end

    # [["Mailbox/changes", %{}, "0"],
    # ["Mailbox/get", %{"list" => []}, "updated"]]
    def new([
          ["Mailbox/changes", _, _],
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
        updated: Mailboxes.new(state, updated)
      }
    end

    def new([
          ["Thread/changes", _, _],
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
        updated: Threads.new(state, updated)
      }
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
