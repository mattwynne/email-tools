defmodule Fastmail.Contacts.Groups do
  import SweetXml

  def from_xml(xml) do
    xml
    |> xpath(~x"/*/response"l)
    |> tl()
    |> Enum.map(&Fastmail.Contacts.Group.from_xml/1)
  end
end
