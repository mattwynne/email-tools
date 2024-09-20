defmodule Fastmail.Request do
  # TODO: consider making these private methods on WebService

  def method_calls(url, token, method_calls) do
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
          using: ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail"],
          methodCalls: method_calls
        })
    )
  end
end
