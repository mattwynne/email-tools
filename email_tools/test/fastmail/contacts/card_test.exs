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
