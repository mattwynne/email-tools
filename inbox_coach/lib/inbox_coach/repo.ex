defmodule InboxCoach.Repo do
  use Ecto.Repo,
    otp_app: :inbox_coach,
    adapter: Ecto.Adapters.Postgres
end
