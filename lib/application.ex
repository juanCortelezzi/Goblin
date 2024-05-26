defmodule Server.Application do
  require Logger

  use Application

  def start(_type, _args) do
    Logger.info("Starting application...")

    children = [
      {Registry.Supervisor, []},
      {ThousandIsland, [port: 1234, handler_module: Server.Handler]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
