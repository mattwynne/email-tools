defmodule Fastmail.Jmap.Credentials do
  defstruct [:token]

  def null() do
    %__MODULE__{
      token: "some-token"
    }
  end

  def from_environment(key \\ "FASTMAIL_API_TOKEN") do
    %__MODULE__{
      token: System.fetch_env!(key)
    }
  end
end
