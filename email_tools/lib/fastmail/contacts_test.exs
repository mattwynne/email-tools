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
      # TODO: create a new
      card = Card.for_group(name: "Feed")
      Contacts.add!(contacts, card)

      assert [card = %Card.Group{}] = get_cards(contacts)
      assert card.name == "Feed"
    end

    test "creates a contact", %{contacts: contacts} do
      # TODO: take a list of properties here, like Individual.new(Property.Email.new("test@test.com", :default), Property.SructuredName.new(:etc.)
      # TODO: more validation of properties when constructing
      email = Faker.Internet.email()
      name = Faker.Person.name()
      formatted_name = Faker.Person.name()
      card = Card.for_individual(name: name, formatted_name: formatted_name, email: email)
      Contacts.add!(contacts, card)

      assert [card = %Card.Individual{}] = get_cards(contacts)
      assert card.email == email
    end

    #     test "lists groups", %{config: config} do
    #       {:ok, contacts} = Contacts.create(config)
    #       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Friends"))
    #       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Family"))
    #       :ok = Contacts.create_contact(contacts, EmailAddress.of("test@test.com"))

    #       groups = Contacts.groups(contacts)
    #       assert length(groups) == 2
    #       assert Enum.map(groups, & &1.name) == ["Friends", "Family"]
    #     end

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

# defmodule Fastmail.ContactsTest do
#   use ExUnit.Case, async: true

#   defmodule ContactsChange do
#     defstruct [:action, :group, :email_address]
#   end

#   alias Fastmail.Contacts
#   alias Fastmail.Contacts.{ContactsGroup, Contact}

#   describe "creating groups in null mode" do
#     setup do
#       {:ok, contacts: Contacts.create_null()}
#     end

#     test "throws an error when creating a group fails", %{contacts: contacts} do
#       assert {:error, %{message: "Failure"}} =
#                Contacts.create_group_named(contacts, ContactsGroupName.of("Fails"))
#     end

#     test "emits an event", %{contacts: contacts} do
#       changes = Contacts.track_changes(contacts)
#       group = ContactsGroupName.of("Friends")
#       :ok = Contacts.create_group_named(contacts, group)

#       assert changes.data == [
#                %ContactsChange{
#                  action: "create-group",
#                  group: group
#                }
#              ]
#     end
#   end

#   describe "creating contacts in null mode" do
#     setup do
#       {:ok, contacts: Contacts.create_null()}
#     end

#     test "throws an error when creating a contact fails", %{contacts: contacts} do
#       assert {:error, %{message: "Failure"}} =
#                Contacts.create_contact(contacts, EmailAddress.of("fail@example.com"))
#     end

#     test "emits an event", %{contacts: contacts} do
#       changes = Contacts.track_changes(contacts)
#       email_address = EmailAddress.of("test@example.com")
#       :ok = Contacts.create_contact(contacts, email_address)

#       assert changes.data == [
#                %ContactsChange{
#                  action: "create-contact",
#                  email_address: email_address
#                }
#              ]
#     end
#   end

#   describe "adding a contact to a group in null mode" do
#     setup do
#       {:ok, contacts: Contacts.create_null()}
#     end

#     test "emits a change event when a contact is added to a group", %{contacts: contacts} do
#       from = EmailAddress.of("somebody@example.com")
#       group = ContactsGroupName.of("Friends")

#       contacts =
#         Contacts.create_null(%{
#           groups: [%ContactsGroup{name: group, id: "1"}],
#           contacts: [%Contact{email: from, id: "2"}]
#         })

#       changes = Contacts.track_changes(contacts)
#       :ok = Contacts.add_to_group(contacts, from, group)

#       assert changes.data == [
#                %ContactsChange{
#                  action: "add-to-group",
#                  email_address: from,
#                  group: group
#                }
#              ]
#     end
#   end

#   test "returns stubbed groups", %{contacts: contacts} do
#     contacts =
#       Contacts.create_null(%{
#         groups: [
#           %ContactsGroup{name: "Friends", id: "1"},
#           %ContactsGroup{name: "Family", id: "2"}
#         ],
#         contacts: []
#       })

#     assert groups = Contacts.groups(contacts)
#     assert Enum.map(groups, & &1.name) == ["Friends", "Family"]
#   end

#   test "returns stubbed contacts", %{contacts: contacts} do
#     contacts =
#       Contacts.create_null(
#         groups: [],
#         contacts: [%Contact{email: "test@test.com", id: "1"}]
#       )

#     assert contacts_list = Contacts.contacts(contacts)
#     assert Enum.map(contacts_list, & &1.email) == ["test@test.com"]
#   end

#   describe "Contacts in connected mode @online" do
#     setup do
#       {:ok, config: FastmailCredentials.create()}
#     end

#     test "creates a group in connected mode", %{config: config} do
#       {:ok, contacts} = Contacts.create(config)
#       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Feed"))
#       assert {:ok, books} = DAVClient.fetch_address_books()
#       assert {:ok, cards} = DAVClient.fetch_vcards(books[0])

#       assert length(cards) == 1
#       assert String.contains?(cards[0].data, "N:Feed")
#       assert String.contains?(cards[0].data, "FN:Feed")
#       assert String.contains?(cards[0].data, "X-ADDRESSBOOKSERVER-KIND:group")
#     end

#     test "creates a contact", %{config: config} do
#       {:ok, contacts} = Contacts.create(config)
#       :ok = Contacts.create_contact(contacts, EmailAddress.of("test@example.com"))
#       assert {:ok, books} = DAVClient.fetch_address_books()
#       assert {:ok, cards} = DAVClient.fetch_vcards(books[0])

#       assert length(cards) == 1
#       assert Regex.match?(~r/EMAIL.*:test@example.com/, cards[0].data)
#     end

#     test "lists groups", %{config: config} do
#       {:ok, contacts} = Contacts.create(config)
#       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Friends"))
#       :ok = Contacts.create_group_named(contacts, ContactsGroupName.of("Family"))
#       :ok = Contacts.create_contact(contacts, EmailAddress.of("test@test.com"))

#       groups = Contacts.groups(contacts)
#       assert length(groups) == 2
#       assert Enum.map(groups, & &1.name) == ["Friends", "Family"]
#     end

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
