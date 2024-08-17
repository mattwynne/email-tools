defmodule EmailTools.FastmailEvents do
  alias Tesla

  def new(token) do
    middleware = [
      {Tesla.Middleware.BearerAuth, token: token},
      {Tesla.Middleware.JSON, decode_content_types: ["text/event-stream"]},
      {Tesla.Middleware.SSE, only: :data}
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: EmailTools.Finch})
  end

  def stream(tesla_client, session) do
    url = session["eventSourceUrl"]
    {:ok, response} = Tesla.get(tesla_client, url, opts: [adapter: [response: :stream]])
    response.body
  end
end
