defmodule EmailTools.Repo.Migrations.AddFastmailApiKeyToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :fastmail_api_key, :binary
    end
  end
end
