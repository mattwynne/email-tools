defmodule Fastmail.Contacts do
  alias Fastmail.Contacts

  defstruct [:config]

  def connect() do
    connect(Contacts.Credentials.from_environment())
  end

  def connect(%Contacts.Credentials{} = credentials) do
    config =
      Webdavex.Config.new(
        base_url:
          "https://carddav.fastmail.com/dav/addressbooks/user/#{credentials.username}/Default",
        headers: [{"Authorization", Contacts.Credentials.basic_auth(credentials)}]
      )

    {:ok, _result} = config |> Webdavex.Client.head("/")
    %__MODULE__{config: config}
  end

  def add!(contacts, card = %{uid: uid}) do
    {:ok, _} =
      contacts.config
      |> Webdavex.Client.put("#{uid}.vcf", {:binary, to_string(card)})

    contacts
  end
end
