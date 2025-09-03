defmodule EmailTools.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EmailToolsWeb.Telemetry,
      EmailTools.Vault,
      EmailTools.Repo,
      {DNSCluster, query: Application.get_env(:email_tools, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EmailTools.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EmailTools.Finch},
      # Start a worker by calling: EmailTools.Worker.start_link(arg)
      # {EmailTools.Worker, arg},
      # Start to serve requests, typically the last entry
      EmailToolsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmailTools.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmailToolsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
