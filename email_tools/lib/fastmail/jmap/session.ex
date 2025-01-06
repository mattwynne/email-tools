defmodule Fastmail.Jmap.Session do
  defmodule NullConfig do
    defstruct [:on_get_session]

    def new(opts \\ []) do
      noop = fn ->
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
      end

      on_get_session = Keyword.get(opts, :on_get_session, noop)
      %__MODULE__{on_get_session: on_get_session}
    end
  end

  alias Fastmail.Jmap
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession

  defstruct [:credentials, :web_service, :data, :account_id, :api_url, :event_source_url]

  def null(%NullConfig{} = config) do
    new(Credentials.null(), GetSession.null(config.on_get_session))
  end

  # TODO: rewrite this in the style
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

  # TODO: aim to delete this
  def new(data, %Jmap{} = web_service) do
    %__MODULE__{
      web_service: web_service,
      account_id: account_id(data),
      api_url: api_url(data),
      event_source_url: event_source_url(data)
    }
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
    Req.request(
      Fastmail.Jmap.Get.event_source(session.credentials.token, session.event_source_url)
    )
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
