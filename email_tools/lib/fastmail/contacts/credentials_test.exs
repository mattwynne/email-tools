defmodule Fastmail.Contacts.CredentialsTest do
  alias Fastmail.Contacts.Credentials
  use ExUnit.Case, async: true

  describe to_string(Credentials) do
    test "basic_auth" do
      username = "a-username"
      password = "a-password"

      expected = "Basic YS11c2VybmFtZTphLXBhc3N3b3Jk"

      assert Credentials.new(username, password) |> Credentials.basic_auth() == expected
    end
  end
end
