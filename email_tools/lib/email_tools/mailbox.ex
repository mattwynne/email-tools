defmodule EmailTools.Mailbox do
  def id(mailbox) do
    mailbox["id"]
  end

  def name(mailbox) do
    mailbox["name"]
  end
end
