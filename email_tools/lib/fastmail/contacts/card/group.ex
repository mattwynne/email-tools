defmodule Fastmail.Contacts.Card.Group do
  defstruct [:uid, :name, :rev, :member_uids]

  def new(properties) do
    member_uids =
      Keyword.get_values(properties, :"X-ADDRESSBOOKSERVER-MEMBER")
      |> Enum.map(&String.replace(&1, "urn:uuid:", ""))

    %__MODULE__{
      uid: Keyword.get(properties, :UID),
      rev: Keyword.get(properties, :REV),
      name: Keyword.get(properties, :N),
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
