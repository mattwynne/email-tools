defmodule Fastmail.Contacts do
  alias Fastmail.Contacts.Card
  alias Fastmail.Contacts

  defstruct [:config, :path]

  def connect() do
    connect(Contacts.Credentials.from_environment())
  end

  def connect(%Contacts.Credentials{} = credentials) do
    config =
      Webdavex.Config.new(
        base_url: "https://carddav.fastmail.com/",
        headers: [{"Authorization", Contacts.Credentials.basic_auth(credentials)}]
      )

    path = "dav/addressbooks/user/#{credentials.username}/Default"
    {:ok, _result} = config |> Webdavex.Client.head(path)
    %__MODULE__{config: config, path: path}
  end

  def create_group(contacts, %Contacts.GroupName{value: name}) do
    card = Card.for_group(name: name)

    {:ok, :created} =
      contacts.config
      |> Webdavex.Client.put(path(contacts, "#{card.uid}.vcf"), {:binary, to_string(card)})
  end

  defp path(contacts, file) do
    Path.join([contacts.path, file])
  end
end
