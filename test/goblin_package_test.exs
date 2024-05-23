defmodule GoblinServer.PackageTest do
  use ExUnit.Case, async: true
  doctest GoblinServer.Package

  test "error on invalid package" do
    assert {:error, :invalid_package} == GoblinServer.Package.from_binary(<<>>)
    assert {:error, :invalid_package} == GoblinServer.Package.from_binary(<<1, 0>>)
  end

  test "error on invalid version" do
    assert {:error, :invalid_version} == GoblinServer.Package.from_binary(<<0, 0, 0>>)
  end

  test "error on invalid message type" do
    assert {:error, :invalid_type} == GoblinServer.Package.from_binary(<<1, 10, 0>>)
  end

  test "error on invalid payload length" do
    assert {:error, :payload_incomplete} == GoblinServer.Package.from_binary(<<1, 0, 1>>)
  end

  test "package overflow" do
    package = %GoblinServer.Package{version: 1, type: :echo, length: 1, payload: "h"}
    rest = "i"

    assert {:ok, {package, rest}} ==
             GoblinServer.Package.from_binary(<<1, 0, 1, "hi">>)
  end

  test "parsing location package" do
    package = %GoblinServer.Package{
      version: 1,
      type: :location,
      length: 36,
      payload: %GoblinServer.Package.Payload.Location{
        id: Nanoid.generate(),
        unix_timestamp: DateTime.utc_now() |> DateTime.to_unix(),
        latitude: 37.7749,
        longitude: -122.4194
      }
    }

    binary = GoblinServer.Package.to_binary(package)
    {:ok, {new_package, rest}} = GoblinServer.Package.from_binary(binary)

    assert package == new_package
    assert <<>> == rest
  end

  test "parsing echo package" do
    package = %GoblinServer.Package{
      version: 1,
      type: :echo,
      length: 5,
      payload: <<1, 2, 3, 4, 5>>
    }

    binary = GoblinServer.Package.to_binary(package)
    {:ok, {new_package, rest}} = GoblinServer.Package.from_binary(binary)

    assert new_package == package
    assert <<>> == rest
  end
end
