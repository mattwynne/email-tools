defmodule Fastmail.Contacts do
  alias Uniq.UUID
  alias Fastmail.Contacts

  defstruct [:config]

  def connect() do
    connect(Contacts.Credentials.from_environment())
  end

  def connect(%Contacts.Credentials{} = credentials) do
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

  def create_group(contacts, %Contacts.GroupName{value: name}) do
    # TODO: delegate to Contacts.Group
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
      contacts.config
      |> Webdavex.Client.put("#{uuid}.vcf", {:binary, vcard_string})
  end
end
