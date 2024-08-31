defmodule EmailTools.Email do
  alias EmailTools.Contact

  def id(email) do
    email["id"]
  end

  def mailbox_ids(email) do
    Map.keys(email["mailboxIds"])
  end

  def subject(email) do
    email["subject"]
  end

  def from(email) do
    from = Enum.at(email["from"], 0)
    %Contact{email: from["email"], name: from["name"]}
  end
end
