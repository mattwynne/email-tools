defmodule InboxCoachWeb.UserRegistrationControllerTest do
  # TODO: figure out flickering issue e.g. with seed 377470
  use InboxCoachWeb.ConnCase, async: false

  import InboxCoach.AccountsFixtures
  alias InboxCoach.Accounts

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn
      |> visit("/users/register")
      |> assert_has("h1", text: "Register")
      |> assert_has("a[href='/users/log_in']")
      |> assert_has("form[action='/users/register']")
    end

    test "redirects if already logged in", %{conn: conn} do
      conn
      |> log_in_user(user_fixture())
      |> visit("/users/register")
      |> assert_path("/users/settings")
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in with valid invite code", %{conn: conn} do
      email = unique_user_email()
      Accounts.set_invite_code("secret123")
      user_attrs = valid_user_attributes(email: email)

      conn
      |> visit("/users/register")
      |> fill_in("Email", with: email)
      |> fill_in("Password", with: user_attrs.password)
      |> fill_in("Invite Code", with: "secret123")
      |> click_button("Create an account")
      |> assert_path("/users/settings")
    end

    test "rejects registration without invite code", %{conn: conn} do
      email = unique_user_email()
      user_attrs = valid_user_attributes(email: email)

      conn
      |> visit("/users/register")
      |> fill_in("Email", with: email)
      |> fill_in("Password", with: user_attrs.password)
      |> click_button("Create an account")
      |> assert_has("h1", text: "Register")
      |> refute_has("li", text: email)
    end

    test "render errors for invalid data", %{conn: conn} do
      Accounts.set_invite_code("secret123")

      conn
      |> visit("/users/register")
      |> fill_in("Email", with: "with spaces")
      |> fill_in("Password", with: "too short")
      |> fill_in("Invite Code", with: "wrong_code")
      |> click_button("Create an account")
      |> assert_has("h1", text: "Register")
      |> assert_has("form", text: "must have the @ sign and no spaces")
      |> assert_has("form", text: "should be at least 12 character")
      |> assert_has("form", text: "Invalid invite code")
    end
  end
end
