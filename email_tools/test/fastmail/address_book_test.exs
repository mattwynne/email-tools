defmodule Fastmail.AddressBookTest do
  alias Fastmail.AddressBook
  use ExUnit.Case, async: true
  import SweetXml

  describe "conecting" do
    test "connects using credentials from the environment" do
      credentials = AddressBook.Credentials.from_environment()
      _service = AddressBook.connect(credentials)
    end
  end

  describe "creating groups" do
    address_book = AddressBook.connect()

    {:ok, :created} =
      address_book |> AddressBook.create_group_named(AddressBook.GroupName.of("Feed"))

    IO.gets("Check it was created....")

    credentials = AddressBook.Credentials.from_environment()
    username = credentials.username
    password = credentials.password
    digest = :base64.encode(String.replace(username, "@", "+Default@") <> ":" <> password)
    authorization = "Basic " <> digest

    headers = [
      {"Authorization", authorization},
      {"Depth", "1"},
      {"Content-Type", "text/xml"}
    ]

    url = "https://carddav.fastmail.com/dav/addressbooks/user/#{username}/Default"

    body = "<propfind xmlns='DAV:'><allprop/></propfind>"

    case :hackney.request(:propfind, url, headers, body, []) do
      {:ok, 207, _response_headers, client_ref} ->
        {:ok, body} = :hackney.body(client_ref)

        headers = [{"Authorization", authorization}]

        config =
          Webdavex.Config.new(
            base_url: "https://carddav.fastmail.com/",
            headers: headers
          )

        body
        |> dbg()
        |> xpath(~x"//href/text()"l)
        |> tl()
        |> Enum.each(fn path ->
          dbg([:deleting, path])
          Webdavex.Client.delete(config, to_string(path)) |> dbg()
        end)

      {:ok, status, _headers, _client_ref} ->
        Logger.error("Failed with status: #{status}")
        {:error, :unexpected_status}

      {:error, reason} ->
        Logger.error("Request failed: #{inspect(reason)}")
        {:error, reason}
    end

    # assert {:ok, books} = DAVClient.fetch_address_books()
    # assert {:ok, cards} = DAVClient.fetch_vcards(books[0])

    # assert length(cards) == 1
    # assert String.contains?(cards[0].data, "N:Feed")
    # assert String.contains?(cards[0].data, "FN:Feed")
    # assert String.contains?(cards[0].data, "X-ADDRESSBOOKSERVER-KIND:group")
  end
end
