defmodule Fastmail.Contacts.Credentials do
  defstruct [:username, :password]

  def from_environment() do
    %__MODULE__{
      username: System.fetch_env!("FASTMAIL_USERNAME"),
      password: System.fetch_env!("FASTMAIL_DAV_PASSWORD")
    }
  end
end
