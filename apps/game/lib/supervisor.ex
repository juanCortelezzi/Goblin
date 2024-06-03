defmodule Game do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: GameSupervisor)
  end

  @impl true
  def init(opts \\ []) do
    children = [
      {Task.Supervisor, name: Game.TaskSupervisor},
      {Game.Server, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
