defmodule GoblinServer.Handler.State do
  defstruct previous: <<>>
end

defmodule GoblinServer.Handler do
  use ThousandIsland.Handler

  alias GoblinServer.Packet
  alias GoblinServer.Handler.State

  @impl ThousandIsland.Handler
  def handle_connection(_, _) do
    {:continue, %State{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, %ThousandIsland.Socket{} = socket, %State{} = state) do
    message = state.previous <> data

    case GoblinServer.Packet.from_binary(message) do
      {:ok, {packet, rest}} ->
        handle_packet(packet, socket)
        handle_data(rest, socket, %State{})

      {:error, :payload_incomplete} ->
        {:continue, %State{previous: message}}

      {:error, cause} ->
        {:error, cause, %State{}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_error(reason, %ThousandIsland.Socket{} = _socket, %State{} = _state) do
    IO.inspect(["Error:", reason])
  end

  defp handle_packet(%Packet{} = packet, %ThousandIsland.Socket{} = socket) do
    IO.inspect(["Received:", packet])
    payload = GoblinServer.Packet.to_binary(packet)
    :ok = ThousandIsland.Socket.send(socket, payload)
  end
end
