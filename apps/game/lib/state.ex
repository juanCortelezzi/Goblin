defmodule Game.State do
  use TypedStruct

  alias Game.State

  @type cell :: 0 | 1
  @type position :: non_neg_integer()
  @type world :: list(cell())

  typedstruct enforce: true, opaque: true do
    field(:world, world())
    field(:width, pos_integer())
    field(:height, pos_integer())
  end

  defp handle_data(data) do
    Enum.map(data, fn [{tl, tc, tr}, {left, cell, right}, {bl, bc, br}] ->
      nbors = tl + tc + tr + left + right + bl + bc + br

      cond do
        nbors === 3 -> 1
        nbors < 2 or nbors > 3 -> 0
        true -> cell
      end
    end)
  end

  @spec next_cycle(State.t()) :: State.t()
  def next_cycle(%State{} = state) do
    wrap_pad =
      &(&1
        |> Stream.cycle()
        |> Stream.drop(&2 - 1)
        |> Stream.take(&2 + 2))

    new_world =
      state.world
      |> Stream.chunk_every(state.width)
      |> wrap_pad.(state.height)
      |> Stream.map(&(&1 |> wrap_pad.(state.width)))
      # task data:
      |> Stream.chunk_every(3, 1, :discard)
      |> Stream.map(&Stream.zip/1)
      |> Stream.map(&(&1 |> Stream.chunk_every(3, 1, :discard)))
      # third_stage:
      |> Stream.map(
        &Task.Supervisor.async(
          Game.TaskSupervisor,
          fn -> handle_data(&1) end
        )
      )
      |> Enum.to_list()
      |> Task.await_many()
      # |> IO.inspect()
      |> List.flatten()

    %State{state | world: new_world}
  end

  @spec new(width :: pos_integer(), height :: pos_integer()) :: State.t()
  def new(width, height) when width > 0 and height > 0,
    do: %State{
      world: Stream.cycle([0]) |> Enum.take(width * height),
      width: width,
      height: height
    }

  @spec new_from(
          width :: pos_integer(),
          height :: pos_integer(),
          world :: world()
        ) :: {:ok, State.t()} | :error
  def new_from(width, height, world)
      when width > 0 and height > 0 and length(world) == width * height do
    if Enum.all?(world, fn cell -> cell == 0 or cell == 1 end) do
      {:ok, %State{world: world, width: width, height: height}}
    else
      :error
    end
  end

  @spec get(t(), position(), position()) :: cell()
  def get(%State{} = state, x, y)
      when x >= 0 and y >= 0 and x < state.width and y < state.height,
      do: Enum.at(state.world, state.width * y + x)

  @spec get_coord(State.t(), position()) :: {x :: position(), y :: position()}
  def get_coord(%State{} = state, index)
      when index >= 0 and index < state.width * state.height do
    {y, x} = shitty_division(index, state.width)
    {x, y}
  end

  @spec print(State.t()) :: State.t()
  def print(%State{} = state) do
    state.world
    |> Stream.map(fn n ->
      case n do
        1 -> ?#
        0 -> ?.
      end
    end)
    |> Stream.chunk_every(state.width)
    |> Stream.map(&Stream.concat(&1, [?\n]))
    |> Stream.concat()
    |> Enum.to_list()
    |> IO.puts()

    state
  end

  @spec shitty_division_rec(
          dividend :: position(),
          divisor :: position(),
          quotient :: position()
        ) :: {
          quotient :: position(),
          remainder :: position()
        }
  defp shitty_division_rec(dividend, divisor, quotient) do
    result = dividend - divisor

    if result < 0 do
      {quotient, dividend}
    else
      shitty_division_rec(result, divisor, quotient + 1)
    end
  end

  @spec shitty_division(
          dividend :: position(),
          divisor :: position()
        ) :: {
          quotient :: position(),
          remainder :: position()
        }
  defp shitty_division(dividend, divisor) do
    shitty_division_rec(dividend, divisor, 0)
  end
end
