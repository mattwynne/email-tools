defmodule Fastmail.Contacts.Card.Group do
  alias Fastmail.Contacts.Card.Properties
  defstruct [:uid, :name, :rev, :member_uids]

  def new(properties = %Properties{}) do
    member_uids =
      Properties.get_values(properties, :"X-ADDRESSBOOKSERVER-MEMBER")
      |> Enum.map(&String.replace(&1, "urn:uuid:", ""))

    %__MODULE__{
      uid: Properties.get(properties, :UID).value,
      rev: Properties.get(properties, :REV).value,
      name: Properties.get(properties, :N).value,
      member_uids: member_uids
    }
  end

  defimpl String.Chars do
    def to_string(card) do
      [
        "BEGIN:VCARD",
        "VERSION:3.0",
        "UID:#{card.uid}",
        "N:#{card.name}",
        "FN:#{card.name}",
        "X-ADDRESSBOOKSERVER-KIND:group",
        Enum.map(card.member_uids, &"X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:#{&1}"),
        "REV:#{card.rev}",
        "END:VCARD"
      ]
      |> List.flatten()
      |> Enum.join("\r\n")
    end
  end
end
