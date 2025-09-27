defmodule InboxCoachWeb.UserSessionControllerTest do
  use InboxCoachWeb.ConnCase, async: true

  import InboxCoach.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn
      |> visit("/users/log_in")
      |> assert_has("h1", text: "Log in")
      |> assert_has("a", text: "Register")
      |> assert_has("a", text: "Forgot your password?")
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn
      |> log_in_user(user)
      |> visit("/users/log_in")
      |> assert_path("/")
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn
      |> visit("/users/log_in")
      |> fill_in("Email", with: user.email)
      |> fill_in("Password", with: valid_user_password())
      |> click_button("Log in")
      |> assert_path("/")
      |> visit("/")
      |> assert_has("text", text: user.email)
      |> assert_has("a", text: "Settings")
      |> assert_has("button", text: "Log out")
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn
      |> visit("/users/log_in")
      |> fill_in("Email", with: user.email)
      |> fill_in("Password", with: valid_user_password())
      |> check("Remember me")
      |> click_button("Log in")
      |> assert_path("/")
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn
      |> init_test_session(user_return_to: "/foo/bar")
      |> visit("/users/log_in")
      |> fill_in("Email", with: user.email)
      |> fill_in("Password", with: valid_user_password())
      |> click_button("Log in")
      |> assert_path("/foo/bar")
      |> assert_has("[role=alert]", text: "Welcome back!")
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn
      |> visit("/users/log_in")
      |> fill_in("Email", with: user.email)
      |> fill_in("Password", with: "invalid_password")
      |> click_button("Log in")
      |> assert_has("h1", text: "Log in")
      |> assert_has("[role=alert]", text: "Invalid email or password")
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn
      |> log_in_user(user)
      |> visit("/")
      |> click_button("Log out")
      |> assert_path("/")
      |> assert_has("[role=alert]", text: "Logged out successfully")
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn
      |> visit("/")
      |> click_button("Log out")
      |> assert_path("/")
      |> assert_has("[role=alert]", text: "Logged out successfully")
    end
  end
end
