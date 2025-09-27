defmodule Fastmail.Jmap.SessionTest do
  use ExUnit.Case, async: true
  alias Fastmail.Jmap.MethodCalls.QueryAllEmails
  alias Fastmail.Jmap.Requests.MethodCalls
  alias Fastmail.Jmap.Credentials
  alias Fastmail.Jmap.Requests.GetSession
  alias Fastmail.Jmap.MethodCalls.GetAllMailboxes
  alias Fastmail.Jmap.Session

  describe "connecting" do
    test "connects when created" do
      credentials = Fastmail.Jmap.Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Fastmail.Jmap.Session.new(credentials)
      assert session.credentials == credentials
      assert session.account_id == "u4d014069"
      assert session.api_url == "https://api.fastmail.com/jmap/api/"
      assert session.event_source_url == "https://api.fastmail.com/jmap/event/"
    end

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
    test "can open the stream and check headers" do
      credentials = Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Session.new(credentials)
      {:ok, response} = session.event_source |> Fastmail.Jmap.EventSource.stream()

      ["text/event-stream; charset=utf-8"] =
        Req.Response.get_header(response, "content-type")
    end
  end

  describe "method_calls - null mode" do
    test "with no configuration, returns an empty result whatever you call it with" do
      session = Session.null()

      assert [] = session |> Session.execute(GetAllMailboxes)
    end

    test "allows configuring multiple method call responses" do
      session =
        Session.null(
          execute: fn
            QueryAllEmails, in_mailbox: "Ponies" ->
              MethodCalls.null(
                Req.Response.new(
                  status: 200,
                  body: %{
                    "methodResponses" => [
                      [
                        "Email/query",
                        %{
                          "filter" => %{"inMailbox" => "Ponies"},
                          "ids" => ["email-1", "email-2"]
                        },
                        "0"
                      ]
                    ]
                  }
                )
              )

            GetAllMailboxes, [] ->
              MethodCalls.null(
                Req.Response.new(
                  status: 200,
                  body: %{
                    "methodResponses" => [
                      [
                        "Mailbox/get",
                        %{
                          "list" => [
                            %{"id" => "Ponies"},
                            %{"id" => "Rainbows"}
                          ]
                        },
                        "0"
                      ]
                    ]
                  }
                )
              )
          end
        )

      assert [
               [
                 "Mailbox/get",
                 %{
                   "list" => [
                     %{"id" => "Ponies"},
                     %{"id" => "Rainbows"}
                   ]
                 },
                 "0"
               ]
             ] == session |> Session.execute(GetAllMailboxes)

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
  end

  describe "method_calls - connected mode" do
    test "makes a real request" do
      credentials = Credentials.from_environment("TEST_FASTMAIL_API_TOKEN")
      session = Session.new(credentials)

      assert [
               [
                 "Mailbox/get",
                 %{
                   "list" => [
                     %{"name" => "Inbox"},
                     %{"name" => "Archive"}
                     | _
                   ]
                 },
                 "mailboxes"
               ]
             ] = session |> Session.execute(GetAllMailboxes)
    end
  end
end
