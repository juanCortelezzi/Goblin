defmodule GoblinServer.Handler do
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    with {:ok, package} <- GoblinServer.Packet.from_binary(data) do
      IO.inspect(["Received:", package])
    else
      {:error, _} -> {:error, "Invalid package", state}
    end

    ThousandIsland.Socket.send(socket, state)
    {:continue, state}
  end
end
