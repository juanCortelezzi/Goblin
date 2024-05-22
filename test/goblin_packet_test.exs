defmodule GoblinServer.PacketTest do
  use ExUnit.Case, async: true
  doctest GoblinServer.Packet

  test "error on invalid packet" do
    assert {:error, :invalid_packet} == GoblinServer.Packet.from_binary(<<>>)
    assert {:error, :invalid_packet} == GoblinServer.Packet.from_binary(<<1, 0>>)
  end

  test "error on invalid version" do
    assert {:error, :invalid_version} == GoblinServer.Packet.from_binary(<<0, 0, 0>>)
  end

  test "error on invalid message type" do
    assert {:error, :invalid_type} == GoblinServer.Packet.from_binary(<<1, 10, 0>>)
  end

  test "error on invalid payload length" do
    assert {:error, :payload_incomplete} == GoblinServer.Packet.from_binary(<<1, 0, 1>>)
  end

  test "packet overflow" do
    packet = %GoblinServer.Packet{version: 1, type: :echo, length: 1, payload: "h"}
    rest = "i"

    assert {:ok, {packet, rest}} ==
             GoblinServer.Packet.from_binary(<<1, 0, 1, "hi">>)
  end

  test "parsing location package" do
    package = %GoblinServer.Packet{
      version: 1,
      type: :location,
      length: 36,
      payload: %GoblinServer.Packet.Payload.Location{
        id: Nanoid.generate(),
        unix_timestamp: DateTime.utc_now() |> DateTime.to_unix(),
        latitude: 37.7749,
        longitude: -122.4194
      }
    }

    binary = GoblinServer.Packet.to_binary(package)
    {:ok, {new_package, rest}} = GoblinServer.Packet.from_binary(binary)

    assert package == new_package
    assert <<>> == rest
  end

  test "parsing echo package" do
    package = %GoblinServer.Packet{
      version: 1,
      type: :echo,
      length: 5,
      payload: <<1, 2, 3, 4, 5>>
    }

    binary = GoblinServer.Packet.to_binary(package)
    {:ok, {new_package, rest}} = GoblinServer.Packet.from_binary(binary)

    assert new_package == package
    assert <<>> == rest
  end
end
