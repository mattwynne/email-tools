defmodule Fastmail.Jmap.Collection do
  defstruct [:state, :list]

  def new(state, []) do
    %__MODULE__{state: state, list: []}
  end

  def new(state, [%{id: _} | _] = list) do
    %__MODULE__{state: state, list: list}
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
