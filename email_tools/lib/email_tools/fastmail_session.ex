defmodule FastmailSession do
  alias Emailtools.Requests
  defstruct [:account_id, :event_source_url, :api_url]

  def new(data) do
    %__MODULE__{
      account_id: account_id(data),
      event_source_url: event_source_url(data),
      api_url: api_url(data)
    }
  end

  def fetch(ops \\ []) do
    token = ops[:token]

    req = ops[:req] || Requests.session(token)

    case Req.request(req) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body |> FastmailSession.new()}

      {:ok, %{body: message}} ->
        {:error, RuntimeError.exception(message)}

      {:error, error} ->
        {:error, error}
    end
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
