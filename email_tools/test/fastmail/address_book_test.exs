defmodule Fastmail.AddressBookTest do
  alias Fastmail.AddressBook
  use ExUnit.Case, async: true

  describe "conecting" do
    credentials = AddressBook.Credentials.from_environment()
    _service = AddressBook.connect(credentials)
  end

  describe "creating groups" do
    :ok =
      AddressBook.connect() |> AddressBook.create_group_named(AddressBook.GroupName.of("Feed"))

    # assert {:ok, books} = DAVClient.fetch_address_books()
    # assert {:ok, cards} = DAVClient.fetch_vcards(books[0])

    # assert length(cards) == 1
    # assert String.contains?(cards[0].data, "N:Feed")
    # assert String.contains?(cards[0].data, "FN:Feed")
    # assert String.contains?(cards[0].data, "X-ADDRESSBOOKSERVER-KIND:group")
  end
end
