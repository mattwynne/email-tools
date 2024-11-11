defmodule Fastmail.Contacts.Card do
  require Logger

  defstruct([:name, :uid, :rev, :kind, :formatted_name, :email])

  # TODO: test this. It happens when we try to fetch the vcard for the Default group
  def parse(""), do: :empty_card

  def parse(body) do
    Logger.debug("Attempting to parse vCard: #{inspect(body)}")

    lines =
      String.split(body, "\r\n")
      |> Enum.reject(fn line -> String.trim(line) == "" end)
      |> combine_folded_lines()

    fields =
      lines
      |> Enum.map(fn line -> String.split(line, ":") end)
      |> Enum.map(fn [key, value] -> {key, value} end)
      |> Map.new()

    name = Map.get(fields, "N") |> String.split(";") |> Enum.reject(&(&1 == ""))
    formatted_name = Map.get(fields, "FN")
    email = find_email(fields)
    uid = Map.get(fields, "UID")
    rev = Map.get(fields, "REV")
    kind = if Map.get(fields, "X-ADDRESSBOOKSERVER-KIND") == "group", do: :group

    %__MODULE__{
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

  defp combine_folded_lines([]), do: []

  defp combine_folded_lines([last_line]), do: [last_line]

  defp combine_folded_lines([current_line | tail]) do
    case hd(tail) do
      " " <> next_line ->
        folded_line = current_line <> next_line
        combine_folded_lines([folded_line | tl(tail)])

      _ ->
        [current_line | combine_folded_lines(tail)]
    end
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
