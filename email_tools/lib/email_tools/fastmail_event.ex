defmodule EmailTools.FastmailEvent do
  defstruct [:id, :name, :data]

  def new(message) do
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
