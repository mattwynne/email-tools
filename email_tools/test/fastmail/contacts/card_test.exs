defmodule Fastmail.Contacts.CardTest do
  use ExUnit.Case, async: true
  alias Fastmail.Contacts.Card

  describe "parsing an http response body" do
    test "parses a contact group" do
      body =
        "BEGIN:VCARD\r\nVERSION:3.0\r\nUID:f91bef7c-e405-48ac-9657-e763d5e6a279\r\nN:Feed\r\nFN:Feed\r\nX-ADDRESSBOOKSERVER-KIND:group\r\nREV:20241108T063625Z\r\nEND:VCARD\r\n"

      card = Card.parse(body)
      assert card.name == "Feed"
      assert card.uid == "f91bef7c-e405-48ac-9657-e763d5e6a279"
      assert card.rev == "20241108T063625Z"
    end

    @tag :wip
    test "parses a fastmail contact" do
      body =
        "BEGIN:VCARD\r\nPRODID:-//CyrusIMAP.org//Cyrus \r\n 3.11.0-alpha0-1110-gdd2947cf5-fm-20241..//EN\r\nVERSION:3.0\r\nUID:cee595dd-1819-405a-926a-2ff68119333a\r\nN:Wynne;Matt;;;\r\nFN:Matt Wynne\r\nNICKNAME:\r\nTITLE:\r\nORG:;\r\nEMAIL;TYPE=HOME;TYPE=PREF:test@test.com\r\nNOTE:\r\nREV:20241109T064005Z\r\nEND:VCARD\r\n"

      card = Card.parse(body)
      assert card.uid == "cee595dd-1819-405a-926a-2ff68119333a"
      assert card.formatted_name == "Matt Wynne"
      assert card.name == "Wynne;Matt"
      assert card.email == "test@test.com"
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
