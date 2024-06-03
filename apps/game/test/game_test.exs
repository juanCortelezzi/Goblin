defmodule GameTest do
  use ExUnit.Case
  doctest Game

  alias Game.Server

  setup do
    world =
      [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 1, 1]
      ]
      |> List.flatten()

    _ = start_supervised!({Task.Supervisor, [name: Game.TaskSupervisor]})
    game = start_supervised!({Game.Server, [width: 5, height: 5, world: world]})

    %{game: game}
  end

  test "iterate", %{game: game} do
    new_world =
      [
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 1],
        [0, 0, 0, 1, 1]
      ]
      |> List.flatten()

    assert new_world === Server.iterate(game).world
  end

  test "iterate n", %{game: game} do
    new_world =
      [
        [0, 0, 0, 1, 1],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 0, 1]
      ]
      |> List.flatten()

    assert new_world === Server.iterate(game, 2).world
  end
end
