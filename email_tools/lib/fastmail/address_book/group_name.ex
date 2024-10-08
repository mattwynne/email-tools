defmodule Fastmail.AddressBook.GroupName do
  defstruct [:value]

  def of(name) do
    %__MODULE__{value: name}
  end
end
