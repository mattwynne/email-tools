defmodule Fastmail.Contacts do
  defmodule ContactsGroup do
    defstruct [:name, :id]
  end

  defmodule Contact do
    defstruct [:email, :id]
  end
end
