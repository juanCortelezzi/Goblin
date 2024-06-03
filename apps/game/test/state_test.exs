defmodule Game.StateTest do
  use ExUnit.Case, async: true
  doctest Game.State

  alias Game.State

  setup do
    {:ok, _pid} = Task.Supervisor.start_link(name: Game.TaskSupervisor)
    :ok
  end

  test "new state" do
    width = 2
    height = 5
    %State{width: ^width, height: ^height, world: world} = State.new(width, height)

    expected_width = width * height
    assert expected_width == length(world)
  end

  test "new state with world" do
    width = 2
    height = 3
    world = [0, 1, 0, 1, 1, 0]

    assert {:ok, %State{width: ^width, height: ^height, world: ^world}} =
             State.new_from(width, height, world)
  end

  test "get cell" do
    {:ok, state} = State.new_from(3, 3, [0, 1, 0, 1, 1, 0, 0, 1, 0])
    assert 0 == State.get(state, 0, 0)
    assert 1 == State.get(state, 1, 0)
    assert 0 == State.get(state, 2, 0)
    assert 1 == State.get(state, 0, 1)
    assert 1 == State.get(state, 1, 1)
    assert 0 == State.get(state, 2, 1)
    assert 0 == State.get(state, 0, 2)
    assert 1 == State.get(state, 1, 2)
    assert 0 == State.get(state, 2, 2)
  end

  test "get coords" do
    {:ok, state} = State.new_from(3, 3, [0, 1, 0, 1, 1, 0, 0, 1, 0])
    assert {0, 0} == State.get_coord(state, 0)
    assert {1, 0} == State.get_coord(state, 1)
    assert {2, 0} == State.get_coord(state, 2)
    assert {0, 1} == State.get_coord(state, 3)
    assert {1, 1} == State.get_coord(state, 4)
    assert {2, 1} == State.get_coord(state, 5)
    assert {0, 2} == State.get_coord(state, 6)
    assert {1, 2} == State.get_coord(state, 7)
    assert {2, 2} == State.get_coord(state, 8)
  end

  test "next_cycle" do
    initial_world =
      [
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 1, 1]
      ]

    width = initial_world |> hd() |> length()
    height = initial_world |> length()
    world = initial_world |> List.flatten()
    {:ok, state} = State.new_from(width, height, world)

    step_1 =
      [
        [0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 1, 0, 1],
        [0, 0, 0, 1, 1]
      ]
      |> List.flatten()

    step_2 =
      [
        [0, 0, 0, 1, 1],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1],
        [0, 0, 1, 0, 1]
      ]
      |> List.flatten()

    state_1 = state |> State.next_cycle()
    assert state_1.world == step_1

    state_2 = state_1 |> State.next_cycle()
    assert state_2.world == step_2
  end
end
