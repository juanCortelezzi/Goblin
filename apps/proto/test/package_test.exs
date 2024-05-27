defmodule ProtoTest do
  use ExUnit.Case, async: true
  doctest Proto

  test "error on invalid package" do
    assert {:error, :invalid_package} == Proto.from_binary(<<>>)
    assert {:error, :invalid_package} == Proto.from_binary(<<1, 0>>)
  end

  test "error on invalid version" do
    assert {:error, :invalid_version} == Proto.from_binary(<<0, 0, 0>>)
  end

  test "error on invalid message type" do
    assert {:error, :invalid_type} == Proto.from_binary(<<1, 10, 0>>)
  end

  test "error on invalid payload length" do
    assert {:error, :payload_incomplete} == Proto.from_binary(<<1, 0, 1>>)
  end

  test "package overflow" do
    package = %Proto{version: 1, type: :echo, length: 1, payload: "h"}
    rest = "i"

    assert {:ok, {package, rest}} ==
             Proto.from_binary(<<1, 0, 1, "hi">>)
  end

  test "parsing location package" do
    package = %Proto{
      version: 1,
      type: :location,
      length: 36,
      payload: %Proto.Payload.Location{
        id: Nanoid.generate(),
        unix_timestamp: DateTime.utc_now() |> DateTime.to_unix(),
        latitude: 37.7749,
        longitude: -122.4194
      }
    }

    binary = Proto.to_binary(package)
    {:ok, {new_package, rest}} = Proto.from_binary(binary)

    assert package == new_package
    assert <<>> == rest
  end

  test "parsing echo package" do
    package = %Proto{
      version: 1,
      type: :echo,
      length: 5,
      payload: <<1, 2, 3, 4, 5>>
    }

    binary = Proto.to_binary(package)
    {:ok, {new_package, rest}} = Proto.from_binary(binary)

    assert new_package == package
    assert <<>> == rest
  end
end
