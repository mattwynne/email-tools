defmodule Fastmail.Contacts.CardsResponseTest do
  alias Fastmail.Contacts.CardsResponse
  use ExUnit.Case, async: true

  describe "parse" do
    test "finds multiple cards" do
      body = """
      BEGIN:VCARD\r
      PRODID:-//CyrusIMAP.org//Cyrus\r
       3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN\r
      VERSION:3.0\r
      UID:aea3c442-6880-4e08-8ea4-561ce920346a\r
      N:;;;;\r
      FN:\r
      EMAIL;TYPE=HOME;TYPE=PREF:test1@example.com\r
      NICKNAME:\r
      NOTE:\r
      ORG:;\r
      TITLE:\r
      REV:20241116T062123Z\r
      END:VCARD\r
      BEGIN:VCARD\r
      PRODID:-//CyrusIMAP.org//Cyrus\r
       3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN\r
      VERSION:3.0\r
      UID:1c6cd38e-79be-4902-84bf-0010cc256d07\r
      N:;;;;\r
      FN:\r
      ORG:;\r
      TITLE:\r
      NOTE:\r
      NICKNAME:\r
      EMAIL;TYPE=HOME;TYPE=PREF:test2@example.com\r
      REV:20241116T062135Z\r
      END:VCARD\r
      BEGIN:VCARD\r
      PRODID:-//CyrusIMAP.org//Cyrus\r
       3.11.0-alpha0-1131-gb22d593e1-fm-20241..//EN\r
      VERSION:3.0\r
      UID:6b2cf630-ac03-4ca1-b266-34a451a2d6bb\r
      N:test group\r
      FN:test group\r
      X-ADDRESSBOOKSERVER-KIND:group\r
      X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:1c6cd38e-79be-4902-84bf-0010cc256d07\r
      REV:20241116T062141Z\r
      END:VCARD\r
      """

      cards = CardsResponse.new(body) |> CardsResponse.parse()
      assert Enum.count(cards) == 3
      assert Enum.at(cards, 0).email == "test1@example.com"
      assert Enum.at(cards, 1).email == "test2@example.com"
      assert Enum.at(cards, 2).name == "test group"
    end
  end
end
