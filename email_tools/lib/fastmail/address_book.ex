defmodule Fastmail.AddressBook do
  alias Uniq.UUID
  alias Fastmail.AddressBook

  defstruct [:config]

  def connect() do
    connect(AddressBook.Credentials.from_environment())
  end

  def connect(%AddressBook.Credentials{} = credentials) do
    username = credentials.username
    password = credentials.password
    digest = :base64.encode(String.replace(username, "@", "+Default@") <> ":" <> password)

    headers = [{"Authorization", "Basic " <> digest}]

    config =
      Webdavex.Config.new(
        base_url: "https://carddav.fastmail.com/dav/addressbooks/user/#{username}/Default",
        headers: headers
      )

    {:ok, _result} = config |> Webdavex.Client.head("/")
    %__MODULE__{config: config}
  end

  def create_group_named(address_book, %AddressBook.GroupName{value: name}) do
    uuid = UUID.uuid4()
    rev = DateTime.utc_now() |> DateTime.to_iso8601()

    vcard_string = """
    BEGIN:VCARD\r
    VERSION:3.0\r
    UID:#{uuid}\r
    N:#{name}\r
    FN:#{name}\r
    X-ADDRESSBOOKSERVER-KIND:group\r
    REV:#{rev}\r
    END:VCARD
    """

    {:ok, :created} =
      address_book.config
      |> Webdavex.Client.put("#{uuid}.vcf", {:binary, vcard_string})

    # case @dav.create_vcard(%{
    #        address_book: @address_book,
    #        vCardString: vcard_string,
    #        filename: "#{uuid}.vcf"
    #      }) do
  end
end
