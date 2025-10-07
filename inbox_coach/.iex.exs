alias Fastmail.Jmap.{Repl, Session, Credentials}

# Start the REPL GenServer automatically
{:ok, pid} = Repl.start_link()

# Wrapper module with implicit pid
defmodule DSL do
  @pid pid

  def login(), do: Repl.login(@pid)
  def login(token), do: Repl.login(@pid, token)
  def exec(method, params \\ []), do: Repl.exec(@pid, method, params)
end

import DSL

IO.puts("\n🔧 Fastmail JMAP REPL ready!")
IO.puts("\nUsage:")
IO.puts("  login()                          # Login with TEST_FASTMAIL_API_TOKEN env var")
IO.puts("  login(\"your-api-token\")           # Login with specific token")
IO.puts("  exec(\"Mailbox/get\", ids: nil)")
IO.puts("  exec(\"Email/query\", filter: %{})\n")
