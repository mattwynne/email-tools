defmodule EmailTools.FastmailClientManagerTest do
  use EmailTools.DataCase, async: true

  alias EmailTools.{FastmailClientManager, Accounts}

  import EmailTools.AccountsFixtures

  describe "FastmailClientManager" do
    test "starts account for user with API key" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      assert {:ok, _pid} = FastmailClientManager.start_client_for_user(user)
    end

    test "returns error for user without API key" do
      user = user_fixture()

      assert {:error, :no_api_key} = FastmailClientManager.start_client_for_user(user)
    end

    test "can get account PID after starting" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, pid} = FastmailClientManager.start_client_for_user(user)

      assert FastmailClientManager.get_client_pid(user.id) == pid
    end

    test "returns nil for non-existent account PID" do
      user = user_fixture()

      assert FastmailClientManager.get_client_pid(user.id) == nil
    end

    test "can stop account for user" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, _pid} = FastmailClientManager.start_client_for_user(user)

      assert :ok = FastmailClientManager.stop_client_for_user(user)

      # Wait a bit for the process to terminate
      Process.sleep(10)

      assert FastmailClientManager.get_client_pid(user.id) == nil
    end

    test "restart_account_for_user works correctly" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, old_pid} = FastmailClientManager.start_client_for_user(user)

      {:ok, new_pid} = FastmailClientManager.restart_client_for_user(user)

      assert old_pid != new_pid
      assert FastmailClientManager.get_client_pid(user.id) == new_pid
    end
  end
end