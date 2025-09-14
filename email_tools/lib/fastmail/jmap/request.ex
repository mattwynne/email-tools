defmodule Fastmail.Jmap.Request do
  # TODO: why is this on e function and others are in the Requests module as modules themselves?
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
          using: [
            "urn:ietf:params:jmap:core",
            "urn:ietf:params:jmap:mail"
          ],
          methodCalls: method_calls
        })
    )
  end
end
