defmodule Fastmail.ContactsTest do
  alias Fastmail.Contacts.Credentials
  alias Fastmail.Contacts.Card
  alias Fastmail.Contacts
  use ExUnit.Case, async: false
  require Logger

  describe "conecting" do
    @tag :online
    test "connects using credentials from the environment" do
      credentials = Contacts.Credentials.from_environment()
      _service = Contacts.connect(credentials)
    end
  end

  describe "creating cards" do
    setup(tags) do
      dbg(tags)
      credentials = Credentials.from_environment()
      contacts = Contacts.connect(credentials)
      delete_all(contacts, Contacts.all(contacts))
      {:ok, %{contacts: contacts}}
    end

    @tag :online
    test "creates a group", %{contacts: contacts} do
      card = Card.for_group(name: "Feed")
      Contacts.add!(contacts, card)

      assert [card = %Card.Group{}] = Contacts.all(contacts)
      assert card.name == "Feed"
    end

    @tag :online
    test "creates a contact", %{contacts: contacts} do
      individual = create_individual()
      Contacts.add!(contacts, individual)

      assert [card = %Card.Individual{}] = Contacts.all(contacts)
      assert card.email == individual.email
    end

    @tag :online
    test "lists groups", %{contacts: contacts} do
      contacts
      |> Contacts.add!(Card.for_group(name: "Friends"))
      |> Contacts.add!(Card.for_group(name: "Family"))
      |> Contacts.add!(create_individual())

      groups = Contacts.groups(contacts)
      assert length(groups) == 2
      assert Enum.map(groups, & &1.name) == ["Friends", "Family"]
    end

    @tag :online
    test "lists individuals", %{contacts: contacts} do
      contacts
      |> Contacts.add!(Card.for_group(name: "Friends"))
      |> Contacts.add!(create_individual(email: "test@test.com"))
      |> Contacts.add!(create_individual(email: "someone@test.com"))

      result = Contacts.individuals(contacts)
      assert length(result) == 2
      assert Enum.map(result, & &1.email) == ["test@test.com", "someone@test.com"]
    end

    @tag :online
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

    def delete_all(%Contacts{config: config}, cards) do
      cards
      |> Enum.each(fn card ->
        Webdavex.Client.delete(config, "#{card.uid}.vcf")
      end)
    end
  end
end
