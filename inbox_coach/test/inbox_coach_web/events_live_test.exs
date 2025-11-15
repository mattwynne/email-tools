defmodule InboxCoachWeb.EventsLiveTest do
  use InboxCoachWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import InboxCoach.AccountsFixtures

  alias InboxCoach.Accounts

  describe "EventsLive mount" do
    test "handles missing account gracefully when get_account_pid returns nil", %{conn: conn} do
      # Create a user with API key but don't start an account
      # This will cause get_account_pid to return nil
      user = user_fixture()
      {:ok, user} = Accounts.update_user_fastmail_api_key(user, %{fastmail_api_key: "test_key"})

      conn = log_in_user(conn, user)

      # This should not crash even though no account is running
      assert {:ok, _view, _html} = live(conn, ~p"/events")
    end
  end
end
