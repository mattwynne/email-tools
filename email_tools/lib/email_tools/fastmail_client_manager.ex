defmodule EmailTools.FastmailClientManager do
  @moduledoc """
  A DynamicSupervisor that manages FastmailClient processes for each user.
  Automatically starts clients for users with API keys and provides functions
  to start/stop clients dynamically.
  """
  use DynamicSupervisor
  alias EmailTools.{Accounts, FastmailClient}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a FastmailClient for the given user.
  Returns {:ok, pid} if successful, or {:error, reason} if it fails.
  """
  def start_client_for_user(user) do
    case Accounts.get_user_fastmail_api_key(user) do
      nil ->
        {:error, :no_api_key}

      _api_key ->
        child_spec = {FastmailClient, [user: user, name: via_tuple(user.id)]}
        DynamicSupervisor.start_child(__MODULE__, child_spec)
    end
  end

  @doc """
  Stops the FastmailClient for the given user.
  """
  def stop_client_for_user(user) do
    case get_client_pid(user.id) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @doc """
  Gets the PID of the FastmailClient for the given user ID.
  Returns nil if no client is running for that user.
  """
  def get_client_pid(user_id) do
    case Registry.lookup(EmailTools.FastmailClientRegistry, user_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Starts FastmailClients for all users who have API keys configured.
  Called during application startup.
  """
  def start_clients_for_all_users do
    users_with_api_keys = list_users_with_api_keys()

    Enum.each(users_with_api_keys, fn user ->
      case start_client_for_user(user) do
        {:ok, _pid} ->
          :ok

        {:error, {:already_started, _pid}} ->
          :ok

        {:error, reason} ->
          IO.puts("Failed to start FastmailClient for user #{user.id}: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Restarts the FastmailClient for a user. Useful when their API key changes.
  """
  def restart_client_for_user(user) do
    stop_client_for_user(user)
    start_client_for_user(user)
  end

  defp via_tuple(user_id) do
    {:via, Registry, {EmailTools.FastmailClientRegistry, user_id}}
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
