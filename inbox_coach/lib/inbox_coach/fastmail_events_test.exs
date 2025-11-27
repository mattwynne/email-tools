defmodule InboxCoach.FastmailEventsTest do
  use ExUnit.Case, async: false
  alias Fastmail.Jmap.EventSource
  alias Fastmail.Jmap.Session
  alias InboxCoach.FastmailEvents
  require Logger
  import ExUnit.CaptureLog

  describe "event stream reconnection" do
    test "automatically reconnects when stream ends and logs the narrative" do
      # Temporarily set logger to debug level for this test
      original_level = Application.get_env(:logger, :level)
      Logger.configure(level: :debug)

      test_pid = self()

      # Track connection attempts
      connection_count = Agent.start_link(fn -> 0 end)
      {:ok, agent} = connection_count

      # Create a session where each call to EventSource.stream() returns a finite stream
      # This simulates the server closing the connection
      session = %{
        Session.null()
        | event_source: %{
            EventSource.null()
            | request: %Req.Request{
                adapter: fn _request ->
                  count = Agent.get_and_update(agent, fn c -> {c + 1, c + 1} end)
                  send(test_pid, {:connection_attempt, count})

                  # Return a finite stream with one event
                  response = %Req.Response{
                    status: 200,
                    body: ["event: state\r\ndata: {\"type\":\"connection_#{count}\"}\r\n\r\n"]
                  }

                  {%Req.Request{}, response}
                end
              }
          }
      }

      # Capture logs while running the test
      log =
        capture_log(fn ->
          # Start the event stream
          pid = FastmailEvents.open_stream(session)

          # Should connect initially
          assert_receive {:connection_attempt, 1}, 1000

          # After the first stream ends (finite list is exhausted),
          # it should automatically reconnect
          assert_receive {:connection_attempt, 2}, 2000

          # And again
          assert_receive {:connection_attempt, 3}, 2000

          # Kill the GenServer to stop the infinite reconnection loop
          Process.unlink(pid)
          Process.exit(pid, :kill)
        end)

      # Restore logger level
      Logger.configure(level: original_level)

      # Assert on the log narrative: connect -> success -> ended -> reconnect
      assert log =~ "[debug] [FastmailEvents] Connecting to EventSource stream..."
      assert log =~ "[debug] [FastmailEvents] EventSource stream connected successfully"
      assert log =~ "[info] [FastmailEvents] EventSource stream ended, reconnecting..."

      # Clean up
      Agent.stop(agent)
    end

    test "logs connection failures and retries" do
      # Temporarily set logger to debug level for this test
      Logger.configure(level: :debug)

      test_pid = self()
      attempt_count = Agent.start_link(fn -> 0 end)
      {:ok, agent} = attempt_count

      # Create a custom EventSource that uses Req.request/1 (which returns result tuples)
      # We need to bypass the normal adapter and call Req.request directly
      event_source = %{
        EventSource.null()
        | request: %Req.Request{
            adapter: fn request ->
              count = Agent.get_and_update(agent, fn c -> {c + 1, c + 1} end)
              send(test_pid, {:connection_attempt, count})

              case count do
                1 ->
                  # First attempt fails - return exception directly (not wrapped in error tuple)
                  {request, %RuntimeError{message: "Connection timeout"}}

                _ ->
                  # Second attempt succeeds with finite stream
                  response = %Req.Response{
                    status: 200,
                    body: ["event: state\r\ndata: {\"type\":\"success\"}\r\n\r\n"]
                  }

                  {request, response}
              end
            end
          }
      }

      session = %{Session.null() | event_source: event_source}

      log =
        capture_log(fn ->
          pid = FastmailEvents.open_stream(session)

          # First attempt fails
          assert_receive {:connection_attempt, 1}, 1000
          # Second attempt succeeds
          assert_receive {:connection_attempt, 2}, 2000

          # Kill the GenServer to stop any reconnection attempts
          Process.unlink(pid)
          Process.exit(pid, :kill)
        end)

      # Restore logger level
      Logger.configure(level: :warning)

      # Assert the narrative: connect -> failure -> retry -> connect -> success
      assert log =~ "[debug] [FastmailEvents] Connecting to EventSource stream..."

      assert log =~
               "[error] [FastmailEvents] EventSource connection failed: Connection timeout, retrying..."

      assert log =~ "[debug] [FastmailEvents] EventSource stream connected successfully"

      # Clean up
      Agent.stop(agent)
    end
  end
end
