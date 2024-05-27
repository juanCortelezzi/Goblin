defmodule KV.Registry do
  require Logger

  use GenServer
  use TypedStruct

  alias KV.Bucket

  typedstruct module: State, enforce: true do
    field(:buckets, %{String.t() => pid()}, default: %{})
    field(:references, %{reference() => pid()}, default: %{})
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec create(pid(), String.t()) :: {:ok, pid()} | :error
  def create(registry, name) when is_pid(registry) do
    GenServer.call(registry, {:create, name})
  end

  @spec get(pid(), String.t()) :: pid()
  def get(registry, name) when is_pid(registry) do
    GenServer.call(registry, {:get, name})
  end

  @spec fetch(pid(), String.t()) :: {:ok, pid()} | :error
  def fetch(registry, name) when is_pid(registry) do
    GenServer.call(__MODULE__, {:fetch, name})
  end

  @spec remove(pid(), String.t()) :: :ok
  def remove(registry, name) when is_pid(registry) do
    GenServer.call(registry, {:remove, name})
  end

  @impl true
  def init(_elements) do
    {:ok, %State{}}
  end

  @impl true
  def handle_call({:create, name}, _from, %State{} = state)
      when not is_map_key(state.buckets, name) do
    Logger.debug("creating bucket: #{name}")
    {:ok, bucket} = DynamicSupervisor.start_child(Bucket.Supervisor, {Bucket, %{}})
    ref = Process.monitor(bucket)
    refs = Map.put_new(state.references, ref, name)
    buckets = Map.put_new(state.buckets, name, bucket)
    {:reply, {:ok, bucket}, %State{state | buckets: buckets, references: refs}}
  end

  @impl true
  def handle_call({:create, name}, _from, %State{} = state)
      when is_map_key(state.buckets, name) do
    {:reply, :error, state}
  end

  @impl true
  def handle_call({:get, name}, _from, %State{} = state) do
    case Map.fetch(state.buckets, name) do
      :error ->
        Logger.debug("creating bucket: #{name}")
        {:ok, bucket} = DynamicSupervisor.start_child(Bucket.Supervisor, {Bucket, %{}})
        ref = Process.monitor(bucket)
        refs = Map.put_new(state.references, ref, name)
        buckets = Map.put_new(state.buckets, name, bucket)
        {:reply, bucket, %State{state | buckets: buckets, references: refs}}

      {:ok, bucket} ->
        {:reply, bucket, state}
    end
  end

  @impl true
  def handle_call({:fetch, name}, _from, %State{} = state) do
    case Map.fetch(state.buckets, name) do
      :error ->
        {:reply, :error, state}

      {:ok, bucket} ->
        {:reply, {:ok, bucket}, state}
    end
  end

  @impl true
  def handle_call({:remove, bucket_name}, _from, %State{} = state) do
    case Map.fetch(state.buckets, bucket_name) do
      {:ok, bucket} ->
        :ok = DynamicSupervisor.terminate_child(Bucket.Supervisor, bucket)
        {:reply, bucket, state}

      :error ->
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _, _}, %State{} = state) when is_reference(ref) do
    {bucket_name, references} = Map.pop(state.references, ref)
    Logger.debug("removing bucket: #{bucket_name}")
    buckets = Map.delete(state.buckets, bucket_name)
    {:noreply, %State{state | buckets: buckets, references: references}}
  end
end
