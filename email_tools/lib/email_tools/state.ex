defmodule State do
  def new(state \\ %{}) do
    state
  end

  def connected?(state) do
    Map.has_key?(state, :session)
  end

  def account_id(state) do
    Map.keys(state.session["accounts"]) |> Enum.at(0)
  end

  def api_url(state) do
    state.session["apiUrl"]
  end
end
