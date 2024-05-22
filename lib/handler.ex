defmodule GoblinServer.Handler.State do
  defstruct previous: <<>>
end

defmodule GoblinServer.Handler do
  use ThousandIsland.Handler

  alias GoblinServer.Packet
  alias GoblinServer.Handler.State

  defp handle_packet(%Packet{} = packet, socket, %State{} = _state) do
    IO.inspect(["Received:", packet])
    payload = GoblinServer.Packet.to_binary(packet)
    :ok = ThousandIsland.Socket.send(socket, payload)
  end

  defp parse_packets(data, packets \\ []) when is_binary(data) do
    case GoblinServer.Packet.from_binary(data) do
      {:ok, {packet, <<>>}} ->
        {:ok, Enum.reverse([packet | packets])}

      {:ok, {packet, rest}} ->
        parse_packets(rest, [packet | packets])
    end
  end

  @impl ThousandIsland.Handler
  def handle_connection(_, _) do
    {:continue, %State{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %State{} = state) do
    message = state.previous <> data

    IO.inspect(["Processing Message:", message])

    case parse_packets(message) do
      {:ok, packets} ->
        for packet <- packets do
          handle_packet(packet, socket, state)
        end

        {:continue, %State{}}

      {:error, :payload_incomplete} ->
        {:continue, %State{previous: message}}

      {:error, cause} ->
        {:error, cause, %State{}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_error(reason, _socket, _state) do
    IO.inspect(["Error:", reason])
  end

  # @impl ThousandIsland.Handler
  # def handle_data(data, socket, state) do
  #   with {:ok, package} <- GoblinServer.Packet.from_binary(data) do
  #     IO.inspect(["Received:", package])
  #     payload = GoblinServer.Packet.to_binary(package)
  #     :ok = ThousandIsland.Socket.send(socket, payload)
  #     {:continue, state}
  #   else
  #     {:error, _} -> {:error, "Invalid package", state}
  #   end
  # end
end
