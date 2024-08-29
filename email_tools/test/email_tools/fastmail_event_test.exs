defmodule EmailTools.FastmailEventTest do
  use ExUnit.Case, async: true
  alias EmailTools.FastmailEvent

  test "parsing a message" do
    event =
      FastmailEvent.new(
        "event: state\r\nid: 3260\r\ndata: {\"changed\":{\"u4d014069\":{\"Email\":\"3259\",\"EmailDelivery\":\"3259\",\"Mailbox\":\"3259\",\"Thread\":\"3259\"}},\"type\":\"connect\"}\r\n\r\n"
      )

    assert event.id == "3260"
    assert event.name == "state"

    expected_data = %{
      "changed" => %{
        "u4d014069" => %{
          "Email" => "3259",
          "EmailDelivery" => "3259",
          "Mailbox" => "3259",
          "Thread" => "3259"
        }
      },
      "type" => "connect"
    }

    assert event.data == expected_data
  end
end
