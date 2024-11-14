defmodule Fastmail.Contacts.CardTest do
  use ExUnit.Case, async: true
  alias Fastmail.Contacts.Card

  describe "parsing an http response body" do
    test "parses a contact group" do
      body =
        "BEGIN:VCARD\r\nVERSION:3.0\r\nUID:f91bef7c-e405-48ac-9657-e763d5e6a279\r\nN:Feed\r\nFN:Feed\r\nX-ADDRESSBOOKSERVER-KIND:group\r\nREV:20241108T063625Z\r\nEND:VCARD\r\n"

      card = Card.parse(body)
      assert card.name == ["Feed"]
      assert card.uid == "f91bef7c-e405-48ac-9657-e763d5e6a279"
      assert card.rev == "20241108T063625Z"
    end

    test "parses a fastmail contact" do
      body =
        "BEGIN:VCARD\r\nPRODID:-//CyrusIMAP.org//Cyrus \r\n 3.11.0-alpha0-1110-gdd2947cf5-fm-20241..//EN\r\nVERSION:3.0\r\nUID:cee595dd-1819-405a-926a-2ff68119333a\r\nN:Wynne;Matt;;;\r\nFN:Matt Wynne\r\nNICKNAME:\r\nTITLE:\r\nORG:;\r\nEMAIL;TYPE=HOME;TYPE=PREF:test@test.com\r\nNOTE:\r\nREV:20241109T064005Z\r\nEND:VCARD\r\n"

      card = Card.parse(body)
      assert card.uid == "cee595dd-1819-405a-926a-2ff68119333a"
      assert card.formatted_name == "Matt Wynne"
      assert card.name == ["Wynne", "Matt"]
      assert card.email == "test@test.com"
    end

    test "parses a fastnail contact in a group" do
      body =
        "BEGIN:VCARD\r\nPRODID:-//CyrusIMAP.org//Cyrus \r\n 3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN\r\nVERSION:3.0\r\nUID:24509509-5c6e-47a4-bf97-f6149fc1dc0f\r\nN:;;;;\r\nFN: \r\nORG:;\r\nEMAIL;TYPE=HOME;TYPE=PREF:test@example.com\r\nNOTE:\r\nNICKNAME:\r\nTITLE:\r\nREV:20241114T062906Z\r\nEND:VCARD\r\nBEGIN:VCARD\r\nPRODID:-//CyrusIMAP.org//Cyrus \r\n 3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN\r\nVERSION:3.0\r\nUID:8f0eb36f-9090-4cc7-8459-27fc256cbdb6\r\nN:My test group\r\nFN:My test group\r\nX-ADDRESSBOOKSERVER-KIND:group\r\nX-ADDRESSBOOKSERVER-MEMBER:urn:uuid:24509509-5c6e-47a4-bf97-f6149fc1dc0f\r\nREV:20241114T062914Z\r\nEND:VCARD\r\n"

      card = Card.parse(body)
      assert card.email == "test@example.com"
    end

    test "parses a fastmai group with multiple members" do
      body = """
      BEGIN:VCARD
      PRODID:-//CyrusIMAP.org//Cyrus
      3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN
      VERSION:3.0
      UID:0ea55aa8-e61f-4369-9ac6-1002f6b082f0
      N:My test group
      FN:My test group
      X-ADDRESSBOOKSERVER-KIND:group
      REV:20241114T072544Z
      X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:0dcef2ff-d9fe-4993-8e5c-28259cdcba25
      X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:2f5c0713-9b41-45a7-a7c6-e8c1cf3d4384
      END:VCARD
      """

      card = Card.parse(body)
      assert card.email == "test@example.com"
    end
  end

  describe "creating a card for a group" do
    test "renders a vCard string" do
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

      vcard = Card.for_group(name: name, uid: uid, rev: rev) |> to_string()
      assert vcard == expected
    end
  end
end
