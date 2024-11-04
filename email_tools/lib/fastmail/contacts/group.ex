defmodule Fastmail.Contacts.Group do
  import SweetXml
  defstruct [:name, :id]

  def from_xml(xml) do
    dbg(xml)

    %__MODULE__{name: "Yo", id: ~c"yo-id"}
  end
end
