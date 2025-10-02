defmodule Fastmail.Jmap.Requests.MethodCalls do
  # TODO: Add null version, and tests
  def new(method_calls, url, token) do
    Req.new(
      method: :post,
      url: url,
      headers: [
        {"accept", "application/json"},
        {"content-type", "application/json"}
      ],
      auth: {:bearer, token},
      body:
        Jason.encode!(%{
          using: [
            "urn:ietf:params:jmap:core",
            "urn:ietf:params:jmap:mail"
          ],
          methodCalls: method_calls
        })
    )
  end

  def null(), do: null([])

  def null(%Req.Response{} = response) do
    Req.new(
      adapter: fn request ->
        {
          request,
          response
        }
      end
    )
  end

  def null(method_responses) when is_list(method_responses) do
    null(
      Req.Response.new(
        status: 200,
        body: %{
          "methodResponses" => method_responses
        }
      )
    )
  end
end
