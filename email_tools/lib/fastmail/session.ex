defmodule Fastmail.Session do
  defstruct [:web_service, :data, :account_id, :api_url]

  def create_null(opts \\ []) do
    data = %{
      "accounts" => %{
        "an-account-id" => %{}
      },
      "eventSourceUrl" => "https://myserver.com/events",
      "apiUrl" => "https://myserver.com/api"
    }

    events = opts[:events] || []

    %__MODULE__{
      web_service:
        Fastmail.WebService.create_null(
          get_event_source: fn request ->
            {
              request,
              Req.Response.new(status: 200, body: events)
            }
          end
        ),
      data: data,
      account_id: account_id(data),
      api_url: api_url(data)
    }
  end

  def new(data, web_service) do
    %__MODULE__{
      web_service: web_service,
      data: data,
      account_id: account_id(data),
      api_url: api_url(data)
    }
  end

  def event_stream(session) do
    url = event_source_url(session.data)
    session.web_service |> Fastmail.WebService.get_event_source(url)
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
