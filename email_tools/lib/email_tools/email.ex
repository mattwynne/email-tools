defmodule EmailTools.Email do
  def id(email) do
    email["id"]
  end

  def mailbox_ids(email) do
    Map.keys(email["mailboxIds"])
  end
end
