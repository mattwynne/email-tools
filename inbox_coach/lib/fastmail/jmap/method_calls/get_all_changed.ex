defmodule Fastmail.Jmap.MethodCalls.GetAllChanged do
  defmodule Params do
    defstruct [:account_id, :type, :since_state]
  end

  defmodule Response do
    require Logger
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
            subject: email["subject"],
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
        type: :emails,
        old_state: old_state,
        updated: Collection.new(state, updated)
      }
    end

    def new([
          ["Mailbox/changes", %{"oldState" => old_state, "newState" => _new_state}, _],
          ["Mailbox/get", %{"state" => state, "list" => updated}, "updated"]
        ]) do
      updated = Enum.map(updated, &Mailbox.from_jmap/1)

      %__MODULE__{
        type: :mailboxes,
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
        type: :threads,
        old_state: old_state,
        updated: Collection.new(state, updated)
      }
    end

    def new([["error", _details, _] | _rest] = errors) do
      Logger.error(
        "JMAP error response: #{inspect(errors, pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
      )

      :bad_response
    end

    def new(["error", details, _], _) do
      Logger.error(
        "bad response: #{inspect(details, pretty: true, syntax_colors: IO.ANSI.syntax_colors())}"
      )

      :bad_response
    end

    def apply_to(%__MODULE__{type: :emails} = response, %AccountState{} = account_state) do
      apply_to(response, account_state, fn _ -> :ok end)
    end

    def apply_to(%__MODULE__{type: type, updated: updated}, %AccountState{} = account_state) do
      Map.put(
        account_state,
        type,
        Collection.update(
          Map.get(account_state, type),
          updated
        )
      )
    end

    def apply_to(request, state) do
      Logger.error(
        "[#{__MODULE__}] unable to apply request #{inspect(request, pretty: true, syntax_colors: IO.ANSI.syntax_colors())} to state #{inspect(state, pretty: true)}"
      )

      state
    end

    def apply_to(
          %__MODULE__{type: :emails, updated: updated, old_state: old_state},
          %AccountState{mailbox_emails: mailbox_emails} = account_state,
          on_changed
        ) do
      mailbox_emails =
        Enum.reduce(updated, mailbox_emails, fn email, mailbox_emails ->
          Enum.reduce(mailbox_emails, mailbox_emails, fn {mailbox_id, email_ids},
                                                         mailbox_emails ->
            should_be_in_mailbox? = mailbox_id in email.mailbox_ids
            currently_in_mailbox? = email.id in email_ids

            cond do
              should_be_in_mailbox? and not currently_in_mailbox? ->
                on_changed.(%{
                  type: :email_added_to_mailbox,
                  email_id: email.id,
                  mailbox_id: mailbox_id,
                  old_state: old_state,
                  new_state: updated.state
                })

                Map.update!(mailbox_emails, mailbox_id, &(&1 ++ [email.id]))

              not should_be_in_mailbox? and currently_in_mailbox? ->
                on_changed.(%{
                  type: :email_removed_from_mailbox,
                  email_id: email.id,
                  mailbox_id: mailbox_id,
                  old_state: old_state,
                  new_state: updated.state
                })

                Map.update!(mailbox_emails, mailbox_id, &List.delete(&1, email.id))

              true ->
                mailbox_emails
            end
          end)
        end)

      emails = Collection.update(account_state.emails, updated)

      account_state
      |> Map.put(:emails, emails)
      |> Map.put(:mailbox_emails, mailbox_emails)
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
