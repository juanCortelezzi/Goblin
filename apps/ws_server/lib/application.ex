defmodule Server.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Server.Router, scheme: :http, port: 4000}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Server.Supervisor)
  end
end
