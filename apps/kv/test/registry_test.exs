defmodule KV.RegistryTest do
  use ExUnit.Case, async: false
  doctest KV.Registry

  alias KV.Registry
  alias KV.Bucket

  setup do
    registry = start_supervised!({Registry, %{}})
    %{registry: registry}
  end

  test "closing bucket does not crash registry", %{registry: registry} do
    assert {:ok, bucket} = Registry.create(registry, "shopping")
    Agent.stop(bucket)
    assert :error = Registry.fetch(registry, "shopping")
  end

  test "create bucket", %{registry: registry} do
    assert {:ok, _} = Registry.create(registry, "shopping")
    assert :error = Registry.create(registry, "shopping")
  end

  test "get bucket", %{registry: registry} do
    bucket = Registry.get(registry, "shopping")
    Bucket.set(bucket, "cart", %{"milk" => 1})

    assert bucket == Registry.get(registry, "shopping")
    assert %{"milk" => 1} == Bucket.get(bucket, "cart")
  end
end
