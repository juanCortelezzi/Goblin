defmodule Server.Registry.Bucket do
  use Agent, restart: :temporary

  def start_link(initial_value) when is_map(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  @spec get(pid(), String.t()) :: any()
  def get(bucket, key) when is_pid(bucket) and is_bitstring(key) do
    Agent.get(bucket, fn kvs -> Map.get(kvs, key) end)
  end

  @spec set(pid(), String.t(), any()) :: :ok
  def set(bucket, key, value) when is_pid(bucket) and is_bitstring(key) do
    Agent.update(bucket, fn kvs -> Map.put(kvs, key, value) end)
  end

  @spec getset(pid(), String.t(), any()) :: any()
  def getset(bucket, key, value) when is_pid(bucket) and is_bitstring(key) do
    Agent.get_and_update(bucket, fn kvs ->
      Map.get_and_update(kvs, key, fn old_value -> {old_value, value} end)
    end)
  end

  @spec del(pid(), String.t()) :: :ok
  def del(bucket, key) when is_pid(bucket) and is_bitstring(key) do
    Agent.update(bucket, fn kvs -> Map.delete(kvs, key) end)
  end

  @spec getdel(pid(), String.t()) :: :ok
  def getdel(bucket, key) when is_pid(bucket) and is_bitstring(key) do
    Agent.get_and_update(bucket, fn kvs -> Map.pop(kvs, key) end)
  end
end
