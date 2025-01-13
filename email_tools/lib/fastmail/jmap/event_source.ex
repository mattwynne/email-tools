defmodule Fastmail.Jmap.EventSource do
  alias Fastmail.Jmap.Requests.GetEventSource
  alias Fastmail.Jmap.Session
  defstruct [:request]

  def null(events: events) do
    new(Fastmail.Jmap.Requests.GetEventSource.null(events))
  end

  def new(%Session{} = session) do
    new(GetEventSource.new(session.credentials, session.event_source_url))
  end

  def new(%Req.Request{} = request) do
    %__MODULE__{request: request}
  end

  def stream(%__MODULE__{} = event_source) do
    Req.request(event_source.request)
  end
end
