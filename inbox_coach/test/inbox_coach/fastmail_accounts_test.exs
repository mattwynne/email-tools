defmodule InboxCoach.FastmailAccountsTest do
  use InboxCoach.DataCase, async: true

  alias InboxCoach.{FastmailAccounts, Accounts}

  import InboxCoach.AccountsFixtures

  describe "FastmailAccounts" do
    test "starts account for user with API key" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      assert {:ok, _pid} = FastmailAccounts.start_account_for_user(user)
    end

    test "returns error for user without API key" do
      user = user_fixture()

      assert {:error, :no_api_key} = FastmailAccounts.start_account_for_user(user)
    end

    test "can get account PID after starting" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, pid} = FastmailAccounts.start_account_for_user(user)

      assert FastmailAccounts.get_account_pid(user.id) == pid
    end

    test "returns nil for non-existent account PID" do
      user = user_fixture()

      assert FastmailAccounts.get_account_pid(user.id) == nil
    end

    test "can stop account for user" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, _pid} = FastmailAccounts.start_account_for_user(user)

      assert :ok = FastmailAccounts.stop_account_for_user(user)

      # Wait a bit for the process to terminate
      Process.sleep(10)

      assert FastmailAccounts.get_account_pid(user.id) == nil
    end

    test "restart_account_for_user works correctly" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      {:ok, old_pid} = FastmailAccounts.start_account_for_user(user)

      {:ok, new_pid} = FastmailAccounts.restart_account_for_user(user)

      assert old_pid != new_pid
      assert FastmailAccounts.get_account_pid(user.id) == new_pid
    end
  end
end