defmodule EmailTools.Repo do
  use Ecto.Repo,
    otp_app: :email_tools,
    adapter: Ecto.Adapters.Postgres
end
