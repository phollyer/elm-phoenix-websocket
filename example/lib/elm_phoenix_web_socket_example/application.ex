defmodule ElmPhoenixWebSocketExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    :ets.new(:rooms_table, [:named_table, :public])
    :ets.new(:users_table, [:named_table, :public])

    children = [
      # Start the Telemetry supervisor
      ElmPhoenixWebSocketExampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ElmPhoenixWebSocketExample.PubSub},
      ElmPhoenixWebSocketExampleWeb.Presence,
      # Start the Endpoint (http/https)
      ElmPhoenixWebSocketExampleWeb.Endpoint
      # Start a worker by calling: ElmPhoenixWebSocketExample.Worker.start_link(arg)
      # {ElmPhoenixWebSocketExample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElmPhoenixWebSocketExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElmPhoenixWebSocketExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
