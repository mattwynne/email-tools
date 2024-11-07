defmodule Fastmail.Contacts.Group do
  import SweetXml
  defstruct [:href]

  def from_xml(xml) do
    href = xml |> xpath(~x"/response/href/text()") |> to_string()

    %__MODULE__{href: href}
  end
end
