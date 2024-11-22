defmodule Fastmail.Contacts.Card.Individual do
  defstruct [:uid, :name, :rev, :formatted_name, :email]

  def new(properties) do
    %__MODULE__{
      name: Keyword.get(properties, :N),
      uid: Keyword.get(properties, :UID),
      rev: Keyword.get(properties, :REV),
      formatted_name: Keyword.get(properties, :FN),
      email: find_email(properties)
    }
  end

  defp find_email(properties) do
    keys = Keyword.keys(properties) |> Enum.uniq()

    preferred_email_key =
      Enum.find(keys, fn key ->
        key_parts = key |> to_string() |> String.split(";")
        preferred? = Enum.any?(key_parts, &String.contains?(&1, "PREF"))
        Enum.any?(key_parts, &(&1 == "EMAIL")) && preferred?
      end)

    Keyword.get(properties, preferred_email_key)
  end

  defimpl String.Chars do
    def to_string(card) do
      [
        "BEGIN:VCARD",
        "VERSION:3.0",
        "UID:#{card.uid}",
        "N:#{card.name}",
        "FN:#{card.formatted_name}",
        "REV:#{card.rev}",
        "EMAIL;PREF:#{card.email}",
        "END:VCARD"
      ]
      |> List.flatten()
      |> Enum.join("\r\n")
    end
  end
end
