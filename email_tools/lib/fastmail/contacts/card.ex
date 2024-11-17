defmodule Fastmail.Contacts.Card do
  require Logger

  defstruct([:fields, :name, :uid, :rev, :kind, :formatted_name, :email])

  # TODO: make two structs, one for Group and one for Contact and decide which one to create
  def new(lines) when is_list(lines) do
    fields =
      lines
      |> Enum.map(fn line -> String.split(line, ":", parts: 2) end)
      |> Enum.map(fn [key, value] -> {key, value} end)
      |> Map.new()

    # TODO: Map won't work, at least for groups because for member_ids there are multiple values with the same key

    name = Map.get(fields, "N") |> String.split(";") |> Enum.reject(&(&1 == ""))
    formatted_name = Map.get(fields, "FN")
    email = find_email(fields)
    uid = Map.get(fields, "UID")
    rev = Map.get(fields, "REV")
    kind = if Map.get(fields, "X-ADDRESSBOOKSERVER-KIND") == "group", do: :group
    # member_ids = Map.get(fields, "X-ADDRESSBOOKSERVER-MEMBER")

    %__MODULE__{
      fields: fields,
      name: name,
      uid: uid,
      rev: rev,
      kind: kind,
      formatted_name: formatted_name,
      email: email
    }
  end

  defp find_email(fields) do
    keys = Map.keys(fields)

    preferred_email_key =
      Enum.find(keys, fn key ->
        key_parts = String.split(key, ";")
        preferred? = Enum.any?(key_parts, &String.contains?(&1, "PREF"))
        Enum.any?(key_parts, &(&1 == "EMAIL")) && preferred?
      end)

    Map.get(fields, preferred_email_key)
  end

  # TODO: create a separate struct for group cards
  def for_group(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    uid = Keyword.get(opts, :uid, Uniq.UUID.uuid4())
    rev = Keyword.get(opts, :rev, DateTime.utc_now() |> DateTime.to_iso8601())
    kind = :group
    %__MODULE__{name: name, uid: uid, rev: rev, kind: kind}
  end

  defimpl String.Chars do
    def to_string(card) do
      """
      BEGIN:VCARD\r
      VERSION:3.0\r
      UID:#{card.uid}\r
      N:#{card.name}\r
      FN:#{card.name}\r
      X-ADDRESSBOOKSERVER-KIND:#{card.kind}\r
      REV:#{card.rev}\r
      END:VCARD
      """
    end
  end
end
