defmodule Fastmail.Jmap.EventSource do
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetEventSource
  alias Fastmail.Jmap.Session
  defstruct [:request]

  def null() do
    null(events: [])
  end

  def null(events: events) do
    new(Fastmail.Jmap.Requests.GetEventSource.null(events))
  end

  # TODO: can we delete this now?
  def new(%Session{} = session) do
    new(session.credentials, session.event_source_url)
  end

  def new(%Req.Request{} = request) do
    %__MODULE__{request: request}
  end

  def new(%Credentials{} = credentials, event_source_url) do
    new(GetEventSource.new(credentials, event_source_url))
  end

  def stream(%__MODULE__{} = event_source) do
    Req.request(event_source.request)
  end
end
