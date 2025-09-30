defmodule InboxCoach.FastmailEvent do
  defstruct [:id, :name, :data]

  # TODO: purely for testing. Could this move into the tests somewhere?
  def new(message) when is_map(message) do
    struct!(__MODULE__, data: message)
  end

  def new(message) when is_binary(message) do
    String.split(message, "\r\n")
    |> Enum.reduce(
      %__MODULE__{},
      fn
        "event: " <> name, event -> Map.put(event, :name, name)
        "id: " <> id, event -> Map.put(event, :id, id)
        "data: " <> data, event -> Map.put(event, :data, Jason.decode!(data))
        _, event -> event
      end
    )
  end

  def empty?(%__MODULE__{id: nil, name: nil, data: nil}), do: true
  def empty?(_), do: false
end
