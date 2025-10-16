defmodule Fastmail.Jmap.Threads do
  defstruct [:state, :list]

  def new(state, list) do
    %__MODULE__{state: state, list: list}
  end

  defimpl Enumerable do
    @for Fastmail.Jmap.Threads

    def reduce(_threads, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(threads, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(threads, &1, fun)}
    end

    def reduce(%@for{list: list}, {:cont, acc}, fun) do
      Enumerable.List.reduce(list, {:cont, acc}, fun)
    end

    def count(_threads), do: {:error, __MODULE__}
    def member?(_threads, _element), do: {:error, __MODULE__}
    def slice(_threads), do: {:error, __MODULE__}
  end
end
