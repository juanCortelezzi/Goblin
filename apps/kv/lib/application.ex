defmodule KV.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]

    Supervisor.start_link(children, name: KV.Supervisor, strategy: :one_for_all)
  end
end
