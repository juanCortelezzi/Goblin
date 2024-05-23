defmodule GoblinServer.Handler.State do
  defstruct previous: <<>>
end

defmodule GoblinServer.Handler do
  use ThousandIsland.Handler

  alias GoblinServer.Handler.State
  alias GoblinServer.Package

  @impl ThousandIsland.Handler
  def handle_connection(_, _) do
    {:continue, %State{}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, %ThousandIsland.Socket{} = socket, %State{} = state) do
    message = state.previous <> data

    case GoblinServer.Package.from_binary(message) do
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
    IO.puts("Error: #{reason}")
  end

  defp handle_package(%Package{} = package, %ThousandIsland.Socket{} = socket) do
    payload = GoblinServer.Package.to_binary(package)
    :ok = ThousandIsland.Socket.send(socket, payload)
  end
end
