defmodule Game.Server do
  use GenServer

  alias Game.State

  @type opts :: [width: pos_integer(), height: pos_integer(), world: State.world()]

  @spec start_link(opts) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec get(pid()) :: State.t()
  def get(game) when is_pid(game) do
    GenServer.call(game, :get)
  end

  @spec iterate(pid()) :: State.t()
  def iterate(game) when is_pid(game) do
    GenServer.call(game, {:iterate, 1})
  end

  @spec iterate(pid(), pos_integer()) :: State.t()
  def iterate(game, iterations) when is_pid(game) and iterations > 0 do
    GenServer.call(game, {:iterate, iterations})
  end

  @impl true
  def init(options \\ []) do
    width = Keyword.get(options, :width, 5)
    height = Keyword.get(options, :height, 5)

    case Keyword.fetch(options, :world) do
      {:ok, world} ->
        {:ok, state} = State.new_from(width, height, world)
        {:ok, state}

      _ ->
        {:ok, state} = State.new(width, height)
        {:ok, state}
    end
  end

  @impl true
  def handle_call({:iterate, iterations}, _from, %State{} = state) when iterations > 0 do
    new_state =
      Stream.scan(1..iterations, state, fn _, acc -> State.next_cycle(acc) end)
      |> Stream.drop(iterations - 1)
      |> Enum.at(0)

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get, _from, %State{} = state) do
    {:reply, state, state}
  end
end
