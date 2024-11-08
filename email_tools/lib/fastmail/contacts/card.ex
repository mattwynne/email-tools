defmodule Fastmail.Contacts.Card do
  defstruct([:name, :uid, :rev, :kind])

  def parse(body) do
    fields =
      String.split(body, "\r\n")
      |> Enum.reject(fn line -> String.trim(line) == "" end)
      |> Enum.map(fn line -> String.split(line, ":") end)
      |> Enum.map(fn [key, value] -> {key, value} end)
      |> Map.new()

    name = Map.get(fields, "N")
    uid = Map.get(fields, "UID")
    rev = Map.get(fields, "REV")
    kind = if Map.get(fields, "X-ADDRESSBOOKSERVER-KIND") == "group", do: :group

    %__MODULE__{name: name, uid: uid, rev: rev, kind: kind}
  end

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
