defmodule Fastmail.Session do
  defstruct [:account_id, :event_source_url, :api_url]

  def parse(data) do
    %__MODULE__{
      account_id: account_id(data),
      event_source_url: event_source_url(data),
      api_url: api_url(data)
    }
  end

  defp account_id(data) do
    Map.keys(data["accounts"]) |> Enum.at(0)
  end

  defp event_source_url(data) do
    data["eventSourceUrl"]
  end

  defp api_url(data) do
    data["apiUrl"]
  end
end
