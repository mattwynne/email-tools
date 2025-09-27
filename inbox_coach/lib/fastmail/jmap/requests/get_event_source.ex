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

  def null(events) do
    Req.new(
      adapter: fn request ->
        {
          request,
          Req.Response.new(status: 200, body: events)
        }
      end
    )
  end
end
