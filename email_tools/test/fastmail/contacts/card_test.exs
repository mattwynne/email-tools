defmodule Fastmail.Contacts.CardTest do
  use ExUnit.Case, async: true
  alias Fastmail.Contacts.Card.Individual
  alias Fastmail.Contacts.Card.Property.StructuredName
  alias Fastmail.Contacts.Card
  alias Fastmail.Contacts.Card.Group

  describe "parsing an http response body" do
    test "parses a fastmail group" do
      lines = [
        "VERSION:3.0",
        "UID:f91bef7c-e405-48ac-9657-e763d5e6a279",
        "N:Feed",
        "FN:Feed",
        "X-ADDRESSBOOKSERVER-KIND:group",
        "REV:20241108T063625Z"
      ]

      card = Card.new(lines)
      assert card.name == "Feed"
      assert card.uid == "f91bef7c-e405-48ac-9657-e763d5e6a279"
      assert card.rev == "20241108T063625Z"
      assert %Group{} = card
    end

    test "parses a fastmail individual" do
      lines = [
        "PRODID:-//CyrusIMAP.org//Cyrus 3.11.0-alpha0-1110-gdd2947cf5-fm-20241..//EN",
        "VERSION:3.0",
        "UID:cee595dd-1819-405a-926a-2ff68119333a",
        "N:Wynne;Matt;;;",
        "FN:Matt Wynne",
        "NICKNAME:",
        "TITLE:",
        "ORG:;",
        "EMAIL;TYPE=HOME;TYPE=PREF:test@test.com",
        "NOTE:",
        "REV:20241109T064005Z"
      ]

      card = Card.new(lines)
      assert card.uid == "cee595dd-1819-405a-926a-2ff68119333a"
      assert card.formatted_name == "Matt Wynne"
      assert %StructuredName{family_name: "Wynne", given_name: "Matt"} = card.name
      assert card.email == "test@test.com"
      assert %Individual{} = card
    end

    test "parses a group with multiple members" do
      lines =
        [
          "PRODID:-//CyrusIMAP.org//Cyrus 3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN",
          "VERSION:3.0",
          "UID:0ea55aa8-e61f-4369-9ac6-1002f6b082f0",
          "N:My test group",
          "FN:My test group",
          "X-ADDRESSBOOKSERVER-KIND:group",
          "REV:20241114T072544Z",
          "X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:0dcef2ff-d9fe-4993-8e5c-28259cdcba25",
          "X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:2f5c0713-9b41-45a7-a7c6-e8c1cf3d4384"
        ]

      card = Card.new(lines)

      assert card.member_uids == [
               "0dcef2ff-d9fe-4993-8e5c-28259cdcba25",
               "2f5c0713-9b41-45a7-a7c6-e8c1cf3d4384"
             ]
    end
  end

  describe "creating a new card for a group" do
    test "renders a vCard string for a group with members" do
      uid = Uniq.UUID.uuid4()
      rev = DateTime.utc_now() |> DateTime.to_iso8601()
      name = "A group name"

      member_uids = [
        "0dcef2ff-d9fe-4993-8e5c-28259cdcba25",
        "2f5c0713-9b41-45a7-a7c6-e8c1cf3d4384"
      ]

      expected = """
      BEGIN:VCARD\r
      VERSION:3.0\r
      UID:#{uid}\r
      N:#{name}\r
      FN:#{name}\r
      X-ADDRESSBOOKSERVER-KIND:group\r
      X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:0dcef2ff-d9fe-4993-8e5c-28259cdcba25\r
      X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:2f5c0713-9b41-45a7-a7c6-e8c1cf3d4384\r
      REV:#{rev}\r
      END:VCARD
      """

      card =
        Card.for_group(name: name, uid: uid, rev: rev, member_uids: member_uids)
        |> to_string()

      assert card == String.trim(expected)
    end

    test "renders a vCard string for a group with no members" do
      uid = Uniq.UUID.uuid4()
      rev = DateTime.utc_now() |> DateTime.to_iso8601()
      name = "A group name"

      expected = """
      BEGIN:VCARD\r
      VERSION:3.0\r
      UID:#{uid}\r
      N:#{name}\r
      FN:#{name}\r
      X-ADDRESSBOOKSERVER-KIND:group\r
      REV:#{rev}\r
      END:VCARD
      """

      card =
        Card.for_group(name: name, uid: uid, rev: rev)
        |> to_string()

      assert card == String.trim(expected)
    end
  end

  describe "creating a new card for an individual" do
    test "renders a vCard string for an individual" do
      uid = Uniq.UUID.uuid4()
      rev = DateTime.utc_now() |> DateTime.to_iso8601()
      name = "Dr. Test Me Data Phd"
      formatted_name = StructuredName.new("Data;Test;Me;Dr.;Phd")
      # TODO: create a property to model emails
      email = "test@test.com"

      card =
        Card.for_individual(
          uid: uid,
          rev: rev,
          name: name,
          formatted_name: formatted_name,
          email: email
        )
        |> to_string()

      expected = """
      BEGIN:VCARD\r
      VERSION:3.0\r
      UID:#{uid}\r
      N:#{name}\r
      FN:#{formatted_name}\r
      REV:#{rev}\r
      EMAIL:#{email}\r
      END:VCARD
      """

      assert card === String.trim(expected)
    end
  end
end
