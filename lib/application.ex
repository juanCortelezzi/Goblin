defmodule GoblinServer.Application do
  require Logger

  use Application

  def start(_type, _args) do
    Logger.info("Starting application...")
    GoblinServer.Supervisor.start_link([])
  end
end

defmodule GoblinServer.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl Supervisor
  def init(:ok) do
    children = [
      {ThousandIsland, [port: 1234, handler_module: GoblinServer.Handler]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
