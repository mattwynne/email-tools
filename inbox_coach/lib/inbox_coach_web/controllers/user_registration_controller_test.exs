defmodule InboxCoachWeb.UserRegistrationControllerTest do
  # TODO: figure out flickering issue e.g. with seed 377470
  use InboxCoachWeb.ConnCase, async: false

  import InboxCoach.AccountsFixtures
  alias InboxCoach.Accounts

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ ~p"/users/log_in"
      assert response =~ ~p"/users/register"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/register")

      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in with valid invite code", %{conn: conn} do
      email = unique_user_email()
      Accounts.set_invite_code("secret123")

      conn =
        post(conn, ~p"/users/register", %{
          "user" => valid_user_attributes(email: email) |> Map.put("invite_code", "secret123")
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      assert "/users/settings" = redirected_to(conn, 302)
    end

    test "rejects registration without invite code", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/users/register", %{
          "user" => valid_user_attributes(email: email)
        })

      response = html_response(conn, 200)
      assert response =~ "Register"
      # Registration was rejected and form is re-rendered
      refute get_session(conn, :user_token)
    end

    test "render errors for invalid data", %{conn: conn} do
      Accounts.set_invite_code("secret123")

      conn =
        post(conn, ~p"/users/register", %{
          "user" => %{
            "email" => "with spaces",
            "password" => "too short",
            "invite_code" => "wrong_code"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
      assert response =~ "Invalid invite code"
      # Registration was rejected and form is re-rendered
      refute get_session(conn, :user_token)
    end
  end
end
