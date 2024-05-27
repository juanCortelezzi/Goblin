defmodule TcpServer.Application do
  require Logger

  use Application

  def start(_type, _args) do
    Logger.info("Starting TcpServer...")

    children = [
      {ThousandIsland, [port: 1234, handler_module: TcpServer.Handler]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
