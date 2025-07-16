defmodule Mylibrarynew.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MylibrarynewWeb.Telemetry,
      Mylibrarynew.Repo,
      {DNSCluster, query: Application.get_env(:mylibrarynew, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mylibrarynew.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Mylibrarynew.Finch},
      # Start a worker by calling: Mylibrarynew.Worker.start_link(arg)
      # {Mylibrarynew.Worker, arg},
      # Start to serve requests, typically the last entry
      MylibrarynewWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mylibrarynew.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MylibrarynewWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
