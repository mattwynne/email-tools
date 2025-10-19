defmodule Fastmail.Jmap.Requests.GetEventSource do
  alias Fastmail.Jmap.Credentials

  def new(%Credentials{token: token}, url) do
    Req.new(
      method: :get,
      url: url,
      headers: [
        {"accept", "text/event-stream"}
        # "last-event-id" => state.last_event_id
      ],
      auth: {:bearer, token},
      into: :self,
      receive_timeout: :infinity
    )
  end

  def null(canned_events) when is_list(canned_events) do
    Req.new(
      adapter: fn request ->
        {
          request,
          Req.Response.new(status: 200, body: canned_events)
        }
      end
    )
  end

  def null(stub_events) when is_function(stub_events, 0) do
    Req.new(
      adapter: fn request ->
        {
          request,
          Req.Response.new(
            status: 200,
            body: Stream.repeatedly(stub_events)
          )
        }
      end
    )
  end
end
