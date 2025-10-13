defmodule Fastmail.Jmap.Mailboxes do
  defstruct [:state, :list]

  def new(state, list) do
    %__MODULE__{state: state, list: list}
  end

  defimpl Enumerable do
    def reduce(_mailboxes, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(mailboxes, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(mailboxes, &1, fun)}
    end

    def reduce(%@for{list: list}, {:cont, acc}, fun) do
      Enumerable.List.reduce(list, {:cont, acc}, fun)
    end

    def count(_mailboxes), do: {:error, __MODULE__}
    def member?(_mailboxes, _element), do: {:error, __MODULE__}
    def slice(_mailboxes), do: {:error, __MODULE__}
  end
end
