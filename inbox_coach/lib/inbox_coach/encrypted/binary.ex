defmodule InboxCoach.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: InboxCoach.Vault
end
