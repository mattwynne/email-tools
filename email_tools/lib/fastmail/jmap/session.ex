defmodule Fastmail.Jmap.Session do
  defmodule NullConfig do
    defstruct [:get_session]

    def new(opts \\ []) do
      default_response =
        Req.Response.new(
          status: 200,
          body: %{
            "accounts" => %{
              "some-account-id" => %{}
            },
            "eventSourceUrl" => "https://myserver.com/events",
            "apiUrl" => "https://myserver.com/api"
          }
        )

      get_session = Keyword.get(opts, :get_session, default_response)
      %__MODULE__{get_session: get_session}
    end
  end

  alias Fastmail.Jmap.Requests.GetEventSource
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.Requests.GetEventSource

  defstruct [:credentials, :web_service, :data, :account_id, :api_url, :event_source_url]

  def null(%NullConfig{} = config) do
    new(Credentials.null(), GetSession.null(config.get_session))
  end

  # TODO: rewrite this in the new style
  def null(opts) do
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
        Fastmail.Jmap.null(
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

  def event_stream(%__MODULE__{} = session) do
    # TODO: test, including error cases
    Req.request(GetEventSource.new(session.credentials, session.event_source_url))
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
