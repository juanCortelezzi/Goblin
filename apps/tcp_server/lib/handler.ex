defmodule TcpServer.Handler do
  require Logger

  use ThousandIsland.Handler
  use TypedStruct

  alias Server.Handler.State

  typedstruct module: State, enforce: true do
    field(:previous, binary(), default: <<>>)
  end

  @impl ThousandIsland.Handler
  def handle_connection(_, _) do
    {:continue, %State{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, %ThousandIsland.Socket{} = socket, %State{} = state) do
    message = state.previous <> data

    case Proto.from_binary(message) do
      {:ok, {package, rest}} ->
        true = 255 >= byte_size(package.payload)
        handle_package(package, socket)
        handle_data(rest, socket, %State{})

      {:error, :payload_incomplete} ->
        {:continue, %State{previous: message}}

      {:error, cause} ->
        {:error, cause, %State{}}
    end
  end

  @impl ThousandIsland.Handler
  def handle_error(reason, %ThousandIsland.Socket{} = _socket, %State{} = _state) do
    Logger.error(%{reason: reason})
  end

  defp handle_package(%Proto{} = package, %ThousandIsland.Socket{} = socket) do
    payload = Proto.to_binary(package)
    :ok = ThousandIsland.Socket.send(socket, payload)
  end
end
