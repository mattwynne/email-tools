defmodule Fastmail.Contacts.Card do
  require Logger

  defmodule Property do
    alias Fastmail.Contacts.Card.Property.StructuredName
    alias Fastmail.Contacts.Card.Property.Value

    def parse(line) do
      [name, value] = String.split(line, ":", parts: 2)

      value_type =
        Enum.find(
          [
            StructuredName,
            Value
          ],
          & &1.matches?(name, value)
        )

      {String.to_atom(name), value_type.new(value)}
    end

    defmodule Value do
      def matches?(_, _) do
        true
      end

      def new(value) do
        value
      end
    end

    defmodule StructuredName do
      defstruct [
        :family_name,
        :given_name,
        :additional_names,
        :honorific_prefixes,
        :honorific_suffixes
      ]

      def matches?("N", value) do
        Regex.match?(~r/;/, value)
      end

      def matches?(_name, _) do
        false
      end

      def new(value) do
        [
          family_name,
          given_name,
          additional_names,
          honorific_prefixes,
          honorific_suffixes
        ] = String.split(value, ";")

        %__MODULE__{
          family_name: family_name,
          given_name: given_name,
          additional_names: additional_names,
          honorific_prefixes: honorific_prefixes,
          honorific_suffixes: honorific_suffixes
        }
      end
    end
  end

  defmodule Individual do
    defstruct [:uid, :name, :rev, :formatted_name, :email]

    def new(properties) do
      %Individual{
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
  end

  defmodule Group do
    defstruct [:uid, :name, :rev, :member_uids]

    def new(properties) do
      member_uids =
        Keyword.get_values(properties, :"X-ADDRESSBOOKSERVER-MEMBER")
        |> Enum.map(&String.replace(&1, "urn:uuid:", ""))

      %Group{
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
        # |> Enum.filter(&is_nil(&1))
        |> Enum.join("\r\n")
      end
    end
  end

  def new(lines) when is_list(lines) do
    properties =
      lines
      |> Enum.map(&Property.parse/1)

    if Keyword.get(properties, :"X-ADDRESSBOOKSERVER-KIND") == "group" do
      Group.new(properties)
    else
      Individual.new(properties)
    end
  end

  def for_group(opts \\ []) do
    name = Keyword.fetch!(opts, :name)
    uid = Keyword.get(opts, :uid, Uniq.UUID.uuid4())
    rev = Keyword.get(opts, :rev, DateTime.utc_now() |> DateTime.to_iso8601())
    member_uids = Keyword.get(opts, :member_uids, [])
    %Group{name: name, uid: uid, rev: rev, member_uids: member_uids}
  end
end
