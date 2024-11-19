defmodule Fastmail.Contacts.Card.Property do
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
