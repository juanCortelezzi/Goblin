defmodule ProtoTest do
  use ExUnit.Case, async: true
  doctest Proto

  test "error on invalid package" do
    assert {:error, :invalid_package} = Proto.from_binary(<<>>)
    assert {:error, :invalid_package} = Proto.from_binary(<<1, 0>>)
  end

  test "error on invalid version" do
    assert {:error, :invalid_version} = Proto.from_binary(<<0, 0, 0>>)
  end

  test "error on invalid message type" do
    invalid_type = length(Proto.package_types()) + 1
    assert {:error, :invalid_type} = Proto.from_binary(<<1, invalid_type, 0>>)
  end

  test "error on invalid payload length" do
    assert {:error, :payload_incomplete} = Proto.from_binary(<<1, 0, 1>>)
  end

  test "package overflow" do
    package = %Proto{version: 1, type: :echo, length: 1, payload: "h"}
    assert {:ok, {^package, "i"}} = Proto.from_binary(<<1, 0, 1, "hi">>)
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

    assert {:ok, {^package, <<>>}} = package |> Proto.to_binary() |> Proto.from_binary()
  end

  test "parsing echo package" do
    package = %Proto{
      version: 1,
      type: :echo,
      length: 5,
      payload: <<1, 2, 3, 4, 5>>
    }

    assert {:ok, {^package, <<>>}} = package |> Proto.to_binary() |> Proto.from_binary()
  end
end
