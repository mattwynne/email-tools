defmodule Fastmail.Contacts.Card.Individual do
  alias Fastmail.Contacts.Card.Properties
  defstruct [:uid, :name, :rev, :formatted_name, :email]

  # TODO: other props
  def new(email: email) do
    %__MODULE__{
      email: email
    }
  end

  def new(properties = %Properties{}) do
    %__MODULE__{
      name: Properties.get(properties, :N).value,
      uid: Properties.get(properties, :UID).value,
      rev: Properties.get(properties, :REV).value,
      formatted_name: Properties.get(properties, :FN).value,
      email: find_email(properties)
    }
  end

  defp find_email(properties) do
    keys = Properties.keys(properties) |> Enum.uniq()

    preferred_email_key =
      Enum.find(keys, fn key ->
        key_parts = key |> to_string() |> String.split(";")
        preferred? = Enum.any?(key_parts, &String.contains?(&1, "PREF"))
        Enum.any?(key_parts, &(&1 == "EMAIL")) && preferred?
      end)

    Properties.get(properties, preferred_email_key).value
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
