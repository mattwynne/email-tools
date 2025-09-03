defmodule EmailTools.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: EmailTools.Vault
end