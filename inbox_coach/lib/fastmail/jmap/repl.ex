defmodule Fastmail.Jmap.Repl do
  use GenServer
  alias Fastmail.Jmap.{Session, Credentials}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def login(pid) do
    pid |> login(Credentials.from_environment())
  end

  def login(pid, token) when is_binary(token) do
    pid |> login(%Credentials{token: token})
  end

  def login(pid, %Credentials{} = credentials) do
    case Session.new(credentials) do
      %Session{} = session ->
        login(pid, session)

      {:error, _} = error ->
        error
    end
  end

  def login(pid, %Session{} = session) do
    GenServer.call(pid, {:login, session})
  end

  def exec(pid, method_name, params \\ []) do
    GenServer.call(pid, {:exec, method_name, params})
  end

  @impl true
  def init(:ok) do
    {:ok, %{session: nil}}
  end

  @impl true
  def handle_call({:login, session}, _from, state) do
    {:reply, :ok, %{state | session: session}}
  end

  @impl true
  def handle_call({:exec, method_name, params}, _from, %{session: session} = state) do
    result = Session.execute(session, method_name, params)
    {:reply, result, state}
  end
end
