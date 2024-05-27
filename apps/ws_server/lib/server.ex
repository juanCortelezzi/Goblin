defmodule WsServer.Handler do
  @behaviour WebSock

  require Logger

  @impl true
  def init(options) do
    {:ok, options}
  end

  @impl true
  def handle_in({data, [opcode: :text]}, state) do
    Logger.info("in<text>: #{data}")
    {:reply, :ok, {:text, data}, state}
  end

  @impl true
  def handle_in({data, [opcode: :binary]}, state) do
    Logger.info("in<binary>: #{data}")
    {:reply, :ok, {:binary, data}, state}
  end

  @impl true
  def handle_info(data, state) do
    Logger.info("handle_info: #{inspect(data)}")
    {:ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("terminate: #{inspect(reason)}")
    {:ok, state}
  end
end
