defmodule EmailTools.FastmailEvent do
  defstruct [:id, :name, :data, :type]

  def new(message) do
    String.split(message, "\r\n")
    |> Enum.reduce(
      %{},
      fn
        "event: " <> name, event -> Map.put(event, :name, name)
        "id: " <> id, event -> Map.put(event, :id, id)
        "data: " <> data, event -> Map.put(event, :data, Jason.decode!(data))
        "", event -> event
      end
    )
  end
end
