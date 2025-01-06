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
end
