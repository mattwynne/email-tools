defmodule Fastmail.ContactsTest do
  alias Fastmail.Contacts.CardsResponse
  alias Fastmail.Contacts.Credentials
  alias Fastmail.Contacts.Card
  alias Fastmail.Contacts
  use ExUnit.Case, async: true
  require Logger

  describe "conecting" do
    test "connects using credentials from the environment" do
      credentials = Contacts.Credentials.from_environment()
      _service = Contacts.connect(credentials)
    end
  end

  setup do
    credentials = Credentials.from_environment()
    contacts = Contacts.connect(credentials)
    cards = get_cards(contacts)
    delete_all(contacts, cards)
    {:ok, %{contacts: contacts}}
  end

  describe "creating cards" do
    test "creates a group", %{contacts: contacts} do
      card = Card.for_group(name: "Feed")
      Contacts.add!(contacts, card)

      assert [card = %Card.Group{}] = get_cards(contacts)
      assert card.name == "Feed"
    end

    test "creates a contact", %{contacts: contacts} do
      individual = create_individual()
      Contacts.add!(contacts, individual)

      assert [card = %Card.Individual{}] = get_cards(contacts)
      assert card.email == individual.email
    end

    test "lists groups", %{contacts: contacts} do
      contacts
      |> Contacts.add!(Card.for_group(name: "Friends"))
      |> Contacts.add!(Card.for_group(name: "Family"))
      |> Contacts.add!(create_individual())

      groups = Contacts.groups(contacts)
      assert length(groups) == 2
      assert Enum.map(groups, & &1.name) == ["Friends", "Family"]
    end

    test "lists individuals", %{contacts: contacts} do
      contacts
      |> Contacts.add!(Card.for_group(name: "Friends"))
      |> Contacts.add!(create_individual(email: "test@test.com"))
      |> Contacts.add!(create_individual(email: "someone@test.com"))

      result = Contacts.individuals(contacts)
      assert length(result) == 2
      assert Enum.map(result, & &1.email) == ["test@test.com", "someone@test.com"]
    end

    test "adds an individual to an existing group", %{contacts: contacts} do
      group = Card.for_group(name: "Friends")
      individual = create_individual(email: "test@test.com")

      [group] =
        contacts
        |> Contacts.add!(group)
        |> Contacts.add!(individual)
        |> Contacts.add_to_group(group, individual)
        |> Contacts.groups()

      assert group.member_uids == [individual.uid]
    end

    defp create_individual(opts \\ []) do
      email = Keyword.get(opts, :email, Faker.Internet.email())
      name = Faker.Person.name()
      formatted_name = Faker.Person.name()

      # TODO: take a list of properties here, like Individual.new(Property.Email.new("test@test.com", :default), Property.SructuredName.new(:etc.)
      # TODO: more validation of properties when constructing
      Card.for_individual(name: name, formatted_name: formatted_name, email: email)
    end
  end

  def delete_all(%Contacts{config: config}, cards) do
    cards
    |> Enum.each(fn card ->
      Webdavex.Client.delete(config, "#{card.uid}.vcf")
    end)
  end

  def get_cards(%Contacts{config: config}) do
    {:ok, body} =
      config
      |> Webdavex.Client.get("/")

    CardsResponse.new(body) |> CardsResponse.parse()
  end
end

#     test "lists contacts", %{config: config} do
#       {:ok, contacts} = Contacts.create(config)
#       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Friends"))
#       :ok = Contacts.create_contact(contacts, EmailAddress.of("test@test.com"))
#       :ok = Contacts.create_contact(contacts, EmailAddress.of("someone@test.com"))

#       contacts_list = Contacts.contacts(contacts)
#       assert length(contacts_list) == 2
#       assert Enum.map(contacts_list, & &1.email) == ["test@test.com", "someone@test.com"]
#     end

#     test "adds a contact to an existing group", %{config: config} do
#       {:ok, contacts} = Contacts.create(config)
#       group = ContactsGroupName.of("Friends")
#       email = EmailAddress.of("test@test.com")
#       :ok = Contacts.create_group_named(contacts, group)
#       :ok = Contacts.create_contact(contacts, email)
#       :ok = Contacts.add_to_group(contacts, email, group)

#       assert {:ok, books} = DAVClient.fetch_address_books()
#       assert {:ok, cards} = DAVClient.fetch_vcards(books[0])

#       assert length(cards) == 2

#       groups =
#         Enum.filter(cards, fn card ->
#           Regex.match?(~r/X-ADDRESSBOOKSERVER-KIND:group/, card.data)
#         end)

#       assert length(groups) == 1
#       assert Regex.match?(~r/X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:/, groups[0].data)
#     end
#   end
# end
