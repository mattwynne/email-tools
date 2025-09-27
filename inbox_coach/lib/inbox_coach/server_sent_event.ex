defmodule InboxCoach.ServerSentEvent do
  def parse(payload) do
    String.split(payload, "\r\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce(
      %{},
      fn line, result ->
        [key, value] = String.split(line, ":", parts: 2) |> Enum.map(&String.trim/1)
        Map.put(result, String.to_atom(key), value)
      end
    )
  end
end
