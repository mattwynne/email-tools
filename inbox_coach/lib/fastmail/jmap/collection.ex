defmodule Fastmail.Jmap.Collection do
  defstruct [:state, :list, :by_id]

  def new(state, []) do
    %__MODULE__{state: state, list: [], by_id: %{}}
  end

  def new(state, [%{id: _} | _] = list) do
    by_id = Map.new(list, fn item -> {item.id, item} end)
    %__MODULE__{state: state, list: list, by_id: by_id}
  end

  def get(%__MODULE__{by_id: by_id}, id) do
    Map.get(by_id, id)
  end

  def update(%__MODULE__{} = existing, %__MODULE__{state: new_state} = updated) do
    updated_map = Map.new(updated, &{&1.id, &1})

    updated_list =
      Enum.map(existing, fn existing_item ->
        if updated_item = Map.get(updated_map, existing_item.id) do
          %type{} = updated_item
          type.merge(existing_item, updated_item)
        else
          existing_item
        end
      end)

    by_id = Map.new(updated_list, fn item -> {item.id, item} end)

    %__MODULE__{state: new_state, list: updated_list, by_id: by_id}
  end

  def update(nil, %__MODULE__{} = updated) do
    updated
  end

  defimpl Enumerable do
    def reduce(_collection, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(collection, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(collection, &1, fun)}
    end

    def reduce(%@for{list: list}, {:cont, acc}, fun) do
      Enumerable.List.reduce(list, {:cont, acc}, fun)
    end

    def count(_collection), do: {:error, __MODULE__}
    def member?(_collection, _element), do: {:error, __MODULE__}
    def slice(_collection), do: {:error, __MODULE__}
  end
end
