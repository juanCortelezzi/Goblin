defmodule Game do
  use GenServer
  use TypedStruct

  defmodule State do
    typedstruct enforce: true do
      field(:world, list(non_neg_integer()))
      field(:width, pos_integer())
      field(:height, pos_integer())
    end

    def new(width, height) when width > 0 and height > 0 do
      %State{
        world: Enum.to_list(0..(width + height)),
        width: width,
        height: height
      }
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    {:ok, %State{}}
  end
end
