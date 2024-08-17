defmodule State do
  def new(state \\ %{}) do
    state
  end

  def connected?(state) do
    Map.has_key?(state, :session)
  end
end
