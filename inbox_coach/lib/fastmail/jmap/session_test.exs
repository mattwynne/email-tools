defmodule Fastmail.Jmap.SessionTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias Fastmail.Jmap.Session

  describe "connecting" do
    @tag :online
    test "connects when created" do
      credentials = Fastmail.Jmap.Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Fastmail.Jmap.Session.new(credentials)
      assert session.credentials == credentials
      assert session.account_id == "u4d014069"
      assert session.api_url == "https://api.fastmail.com/jmap/api/"
      assert session.event_source_url == "https://api.fastmail.com/jmap/event/"
    end

    @tag :online
    test "fails to connect with bad credentials" do
      credentials = Fastmail.Jmap.Credentials.null()

      assert {:error, error} = Fastmail.Jmap.Session.new(credentials)
      assert error.message =~ "Authorization"
    end
  end

  describe "connecting - null mode" do
    test "fails to connect with bad credentials" do
      assert {:error, error} =
               Session.null(
                 get_session:
                   GetSession.null(
                     Req.Response.new(
                       status: 301,
                       body: "Authorization header not a valid format"
                     )
                   )
               )

      assert error.message =~ "Authorization"
    end

    test "fails with a bad URL" do
      assert {:error, error} =
               Session.null(
                 get_session: GetSession.null(RuntimeError.exception("non-existing domain"))
               )

      assert error.message =~ "domain"
    end

    test "connects OK with default null config" do
      assert %Session{} = session = Session.null()
      assert session.account_id == "some-account-id"
      assert session.event_source_url == "https://myserver.com/events"
      assert session.api_url == "https://myserver.com/api"
    end
  end

  describe "event_source - null mode" do
    test "can stream pre-canned events" do
      event_source = Fastmail.Jmap.EventSource.null(events: ["event one", "event two"])
      session = Session.null(event_source: event_source)

      {:ok, response} = session.event_source |> Fastmail.Jmap.EventSource.stream()
      messages = Enum.map(response.body, fn message -> message end)
      assert messages == ["event one", "event two"]
    end
  end

  describe "event_source - connected" do
    @tag :online
    test "can open the stream and check headers" do
      credentials = Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Session.new(credentials)
      {:ok, response} = session.event_source |> Fastmail.Jmap.EventSource.stream()

      ["text/event-stream; charset=utf-8"] =
        Req.Response.get_header(response, "content-type")
    end
  end

  describe "method_calls - null mode" do
    test "with no configuration, throws an error if you try to execute a method call" do
      session = Session.null()

      assert_raise RuntimeError, fn -> Session.execute(session, GetAllMailboxes) end
    end

    test "allows configuring multiple method call responses using a function" do
      session =
        Session.null(
          execute: [
            {{QueryAllEmails, in_mailbox: "Ponies"},
             [
               "Email/query",
               %{
                 "filter" => %{"inMailbox" => "Ponies"},
                 "ids" => ["email-1", "email-2"]
               },
               "0"
             ]},
            {{GetAllMailboxes},
             [
               "Mailbox/get",
               %{
                 "list" => [
                   %{"id" => "Ponies", "name" => "Ponies Mailbox"},
                   %{"id" => "Rainbows", "name" => "Rainbows Mailbox"}
                 ],
                 "state" => "test-state-123"
               },
               "0"
             ]}
          ]
        )

      assert %GetAllMailboxes.Response{
               state: "test-state-123",
               mailboxes: [
                 %Fastmail.Jmap.Mailbox{id: "Ponies", name: "Ponies Mailbox"},
                 %Fastmail.Jmap.Mailbox{id: "Rainbows", name: "Rainbows Mailbox"}
               ]
             } == session |> Session.execute(GetAllMailboxes)

      assert [
               [
                 "Email/query",
                 %{
                   "filter" => %{
                     "inMailbox" => "Ponies"
                   },
                   "ids" => ["email-1", "email-2"]
                 },
                 "0"
               ]
             ] == session |> Session.execute(QueryAllEmails, in_mailbox: "Ponies")
    end

    test "allows configuring multiple method call responses using a list of module/response tuples" do
      session =
        Session.null(
          execute: [
            {{QueryAllEmails, in_mailbox: "Ponies"},
             [
               "Email/query",
               %{
                 "filter" => %{"inMailbox" => "Ponies"},
                 "ids" => ["email-1", "email-2"]
               },
               "0"
             ]},
            {{GetAllMailboxes},
             [
               "Mailbox/get",
               %{
                 "list" => [
                   %{"id" => "Ponies", "name" => "Ponies Mailbox"},
                   %{"id" => "Rainbows", "name" => "Rainbows Mailbox"}
                 ],
                 "state" => "test-state-123"
               },
               "0"
             ]}
          ]
        )

      assert %GetAllMailboxes.Response{
               state: "test-state-123",
               mailboxes: [
                 %Fastmail.Jmap.Mailbox{id: "Ponies", name: "Ponies Mailbox"},
                 %Fastmail.Jmap.Mailbox{id: "Rainbows", name: "Rainbows Mailbox"}
               ]
             } ==
               session |> Session.execute(GetAllMailboxes)

      assert [
               [
                 "Email/query",
                 %{
                   "filter" => %{
                     "inMailbox" => "Ponies"
                   },
                   "ids" => ["email-1", "email-2"]
                 },
                 "0"
               ]
             ] == session |> Session.execute(QueryAllEmails, in_mailbox: "Ponies")
    end

    test "throws a helpful error when trying to call a method that hasn't been stubbed" do
      session =
        Session.null(
          execute: [
            {{QueryAllEmails, in_mailbox: "Ponies"},
             [
               "Email/query",
               %{
                 "filter" => %{"inMailbox" => "Ponies"},
                 "ids" => ["email-1", "email-2"]
               },
               "0"
             ]}
          ]
        )

      assert_raise RuntimeError, fn -> Session.execute(session, GetAllMailboxes) end
    end
  end

  describe "method_calls - connected mode" do
    @tag :online
    test "makes a real request" do
      credentials = Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Session.new(credentials)

      assert %GetAllMailboxes.Response{
               state: state,
               mailboxes: [
                 %Fastmail.Jmap.Mailbox{name: "Inbox"},
                 %Fastmail.Jmap.Mailbox{name: "Archive"}
                 | _
               ]
             } = session |> Session.execute(GetAllMailboxes)

      assert is_binary(state)
    end
  end

  describe "debug logging" do
    test "logs request and response for method calls" do
      session =
        Session.null(
          execute: [
            {{GetAllMailboxes},
             [
               "Mailbox/get",
               %{
                 "list" => [
                   %{"id" => "Ponies", "name" => "Ponies"}
                 ],
                 "state" => "debug-state"
               },
               "0"
             ]}
          ]
        )

      log =
        capture_log(fn ->
          Logger.configure(level: :debug)
          Session.execute(session, GetAllMailboxes)
          Logger.configure(level: :warning)
        end)

      assert log =~ "[jmap-request]"
      assert log =~ "[jmap-response]"
      assert log =~ "methodResponses"
      assert log =~ "Mailbox/get"
    end
  end
end
