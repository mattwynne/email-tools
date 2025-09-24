defmodule Fastmail.Jmap.Requests.MethodCalls do
  # TODO: Add null version, and tests
  def new(url, token, method_calls) do
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
end
