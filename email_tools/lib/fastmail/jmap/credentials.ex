defmodule Fastmail.Jmap.Credentials do
  defstruct [:token]

  def null() do
    %__MODULE__{
      token: "some-token"
    }
  end

  def from_environment() do
    %__MODULE__{
      token: System.fetch_env!("FASTMAIL_API_TOKEN")
    }
  end
end
