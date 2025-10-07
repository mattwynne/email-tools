defmodule Fastmail.Jmap.ReplTest do
  use ExUnit.Case
  alias Fastmail.Jmap.Repl

  describe "start_link/0" do
    test "starts a GenServer" do
      assert {:ok, pid} = Repl.start_link()
      assert Process.alive?(pid)
    end
  end

  describe "login/2" do
    test "stores a session" do
      {:ok, pid} = Repl.start_link()
      session = Fastmail.Jmap.Session.null()

      assert :ok = Repl.login(pid, session)
    end
  end

  describe "exec/3" do
    test "executes a JMAP method call using the session" do
      {:ok, pid} = Repl.start_link()

      session = Fastmail.Jmap.Session.null(
        execute: [
          {{"Mailbox/get", [ids: nil]}, ["Mailbox/get", %{"list" => []}, "0"]}
        ]
      )
      Repl.login(pid, session)

      assert [["Mailbox/get", %{"list" => []}, "0"]] = Repl.exec(pid, "Mailbox/get", ids: nil)
    end
  end
end
