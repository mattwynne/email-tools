defmodule EmailTest do
  use ExUnit.Case, async: true
  alias EmailTools.Contact
  alias EmailTools.Email

  @email %{
    "attachments" => [],
    "bcc" => nil,
    "blobId" => "G1ba9881e530e3410968a1a9be7332ff7092b02b3",
    "bodyValues" => %{},
    "cc" => nil,
    "from" => [%{"email" => "someone@example.com", "name" => "Someone McSomebody"}],
    "hasAttachment" => false,
    "htmlBody" => [
      %{
        "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
        "charset" => "us-ascii",
        "cid" => nil,
        "disposition" => nil,
        "language" => nil,
        "location" => nil,
        "name" => nil,
        "partId" => "1",
        "size" => 0,
        "type" => "text/plain"
      }
    ],
    "id" => "M1ba9881e530e3410968a1a9b",
    "inReplyTo" => nil,
    "keywords" => %{"$seen" => true, "$x-me-annot-2" => true},
    "mailboxIds" => %{"5dc636c7-f5e1-4227-bf10-f43543113fc4" => true},
    "messageId" => ["99b181e7-9ee6-1a24-5cc8-4b4bf5e4d6a0@example.com"],
    "preview" => "",
    "receivedAt" => "2023-12-16T00:22:15Z",
    "references" => nil,
    "replyTo" => nil,
    "sender" => nil,
    "sentAt" => "2023-12-16T00:22:13Z",
    "size" => 9075,
    "subject" => "A subject",
    "textBody" => [
      %{
        "blobId" => "Gda39a3ee5e6b4b0d3255bfef95601890afd80709",
        "charset" => "us-ascii",
        "cid" => nil,
        "disposition" => nil,
        "language" => nil,
        "location" => nil,
        "name" => nil,
        "partId" => "1",
        "size" => 0,
        "type" => "text/plain"
      }
    ],
    "threadId" => "T8a5a51ff58673f02",
    "to" => [%{"email" => "test@levain.codes", "name" => nil}]
  }

  describe "an email" do
    test "id/1" do
      email = %{
        "id" => "some-email-id"
      }

      assert email |> Email.id() == "some-email-id"
    end

    test "mailbox_ids/1" do
      email = %{
        "mailboxIds" => %{"some-mailbox-id" => true}
      }

      assert email |> Email.mailbox_ids() == ["some-mailbox-id"]
    end

    test "subject" do
      assert @email |> Email.subject() == "A subject"
    end

    test "from" do
      assert @email |> Email.from() == %Contact{
               email: "someone@example.com",
               name: "Someone McSomebody"
             }
    end
  end
end
