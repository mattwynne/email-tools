defmodule EmailTools.FastmailAccounts do
  @moduledoc """
  A DynamicSupervisor that manages FastmailAccount processes for each user.
  Automatically starts accounts for users with API keys and provides functions
  to start/stop accounts dynamically.
  """
  use DynamicSupervisor
  alias EmailTools.{Accounts, FastmailAccount}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a FastmailAccount for the given user.
  Returns {:ok, pid} if successful, or {:error, reason} if it fails.
  """
  def start_account_for_user(user) do
    case Accounts.get_user_fastmail_api_key(user) do
      nil ->
        {:error, :no_api_key}

      _api_key ->
        child_spec = {FastmailAccount, [user: user, name: via_tuple(user.id)]}
        DynamicSupervisor.start_child(__MODULE__, child_spec)
    end
  end

  @doc """
  Stops the FastmailAccount for the given user.
  """
  def stop_account_for_user(user) do
    case get_account_pid(user.id) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @doc """
  Gets the PID of the FastmailAccount for the given user ID.
  Returns nil if no account is running for that user.
  """
  def get_account_pid(user_id) do
    case Registry.lookup(EmailTools.FastmailAccountRegistry, user_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Starts FastmailAccounts for all users who have API keys configured.
  Called during application startup.
  """
  def start_accounts_for_all_users do
    users_with_api_keys = list_users_with_api_keys()

    Enum.each(users_with_api_keys, fn user ->
      case start_account_for_user(user) do
        {:ok, _pid} ->
          :ok

        {:error, {:already_started, _pid}} ->
          :ok

        {:error, reason} ->
          IO.puts("Failed to start FastmailAccount for user #{user.id}: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Restarts the FastmailAccount for a user. Useful when their API key changes.
  """
  def restart_account_for_user(user) do
    stop_account_for_user(user)
    start_account_for_user(user)
  end

  defp via_tuple(user_id) do
    {:via, Registry, {EmailTools.FastmailAccountRegistry, user_id}}
  end

  defp list_users_with_api_keys do
    # Query users who have fastmail_api_key set (not nil)
    import Ecto.Query

    from(u in EmailTools.Accounts.User,
      where: not is_nil(u.fastmail_api_key)
    )
    |> EmailTools.Repo.all()
  end
end
