defmodule Server.Registry.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    children = [
      {DynamicSupervisor, name: Server.Registry.Bucket.Supervisor, strategy: :one_for_one},
      {Server.Registry, name: Server.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
