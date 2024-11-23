defmodule Fastmail.Contacts.Card.Properties do
  alias Fastmail.Contacts.Card.Property
  defstruct [:all]

  def new(lines) do
    %__MODULE__{
      all: lines |> Enum.map(&Property.parse/1)
    }
  end

  def get(properties, key) when is_binary(key) do
    key = String.to_atom(key)
    get(properties, key)
  end

  def get(properties, key) when is_atom(key) do
    Enum.find(properties.all, &(&1.key == key)) || none()
  end

  def get_values(properties, key) when is_atom(key) do
    Enum.reduce(properties.all, [], fn prop, result ->
      if prop.key == key do
        [prop.value | result]
      else
        result
      end
    end)
    |> Enum.reverse()
  end

  def keys(properties) do
    Enum.map(properties.all, & &1.key)
  end

  defp none() do
    %Property{key: "", value: ""}
  end
end
