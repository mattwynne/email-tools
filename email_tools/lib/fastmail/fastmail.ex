defmodule Fastmail do
  def jmap do
    credentials = Fastmail.Jmap.Credentials.from_environment()

    Fastmail.Jmap.new(credentials)
    |> Fastmail.Jmap.get_session()
  end

  def carddav do
  end
end
