defmodule Fastmail.Contacts.Credentials do
  alias Fastmail.Contacts.Credentials
  defstruct [:username, :password]

  def new(username, password) do
    %__MODULE__{
      username: username,
      password: password
    }
  end

  def from_environment() do
    new(
      System.fetch_env!("FASTMAIL_USERNAME"),
      System.fetch_env!("FASTMAIL_DAV_PASSWORD")
    )
  end

  def basic_auth(%Credentials{username: username, password: password}) do
    username = String.replace(username, "@", "+Default@")

    digest = :base64.encode(username <> ":" <> password)

    ("Basic " <> digest) |> dbg()
  end
end
