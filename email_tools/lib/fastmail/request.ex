defmodule Fastmail.Request do
  # TODO: consider making these private methods on WebService
  def get_session(token) do
    Req.new(
      method: :get,
      url: "https://api.fastmail.com/jmap/session",
      headers: [
        {"accept", "application/json"}
      ],
      auth: {:bearer, token}
    )
  end
end
