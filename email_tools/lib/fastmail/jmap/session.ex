defmodule Fastmail.Jmap.Session do
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession

  defstruct [:credentials, :account_id, :api_url, :event_source_url]

  def null(response: response) do
    new(Credentials.null(), GetSession.null(response))
  end

  def null() do
    new(Credentials.null(), GetSession.null())
  end

  def new(%Credentials{} = credentials) do
    new(credentials, Fastmail.Jmap.Requests.GetSession.new(credentials))
  end

  def new(%Credentials{} = credentials, %Req.Request{} = get_session) do
    with {:ok, body} <- request(get_session) do
      %__MODULE__{
        credentials: credentials,
        account_id: account_id(body),
        api_url: api_url(body),
        event_source_url: event_source_url(body)
      }
    end
  end

  defp request(%Req.Request{} = request) do
    case Req.request(request) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

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
