defmodule GoblinServer.Packet do
  @doc ~S"""
  Packet and payload definitions for the Goblin protocol.

  ## Examples

    iex> GoblinServer.Packet.from_binary(<<1, 0, 0>>)
    {:ok, %GoblinServer.Packet{version: 1, type: :echo, length: 0, payload: ""}}

    iex> GoblinServer.Packet.from_binary(<<1, 0, 2, "hi">>)
    {:ok, %GoblinServer.Packet{version: 1, type: :echo, length: 2, payload: "hi"}}

  """
  defstruct [:version, :type, :length, :payload]

  defmodule Payload.Location do
    defstruct [:id, :unix_timestamp, :latitude, :longitude]
  end

  @version 1
  @package_types [:echo, :location]

  def from_binary(<<version::integer-size(8)>> <> _)
      when version != @version,
      do: {:error, :invalid_version}

  def from_binary(<<@version, type::integer-size(8)>> <> _)
      when type < 0
      when type >= length(@package_types),
      do: {:error, :invalid_type}

  def from_binary(<<
        @version,
        _::integer-size(8),
        length::integer-size(8),
        payload::binary
      >>)
      when byte_size(payload) != length,
      do: {:error, :invalid_payload_length}

  # BEu is the default for integer
  def from_binary(<<
        @version,
        type::integer-size(8),
        length::integer-size(8),
        payload::binary-size(length)
      >>) do
    type = Enum.at(@package_types, type)

    with {:ok, payload} <- payload_from_binary(type, payload) do
      package = %GoblinServer.Packet{version: @version, type: type, length: length, payload: payload}
      {:ok, package}
    end
  end

  def from_binary(_), do: {:error, :invalid_packet}

  def to_binary(%GoblinServer.Packet{version: version, type: type, length: length, payload: payload}) do
    with {:ok, payload} <- payload_to_binary(type, payload) do
      type = Enum.find_index(@package_types, fn e -> e == type end)

      package = <<
        version::integer-size(8),
        type::integer-size(8),
        length::integer-size(8),
        payload::binary
      >>

      # Ensure the length is correct (sanity check)
      ^length = byte_size(payload)

      {:ok, package}
    end
  end

  # Payload to binary
  def payload_to_binary(:location, %GoblinServer.Packet.Payload.Location{
        id: id,
        unix_timestamp: unix_timestamp,
        latitude: latitude,
        longitude: longitude
      }) do
    payload = <<
      id::binary-size(12),
      unix_timestamp::signed-integer-size(64),
      latitude::float-size(64),
      longitude::float-size(64)
    >>

    {:ok, payload}
  end

  def payload_to_binary(:echo, payload) do
    {:ok, payload}
  end

  def payload_to_binary(_, _) do
    {:err, :invalid_payload}
  end

  # Payload from binary

  def payload_from_binary(type, _) when type not in @package_types do
    {:err, :invalid_payload}
  end

  def payload_from_binary(
        :location,
        <<
          id::binary-size(12),
          unix_timestamp::signed-integer-size(64),
          latitude::float-size(64),
          longitude::float-size(64)
        >>
      ) do
    IO.inspect(["Location package received", {id, unix_timestamp, latitude, longitude}])

    location = %Payload.Location{
      id: id,
      unix_timestamp: unix_timestamp,
      latitude: latitude,
      longitude: longitude
    }

    {:ok, location}
  end

  def payload_from_binary(:echo, data) do
    IO.inspect(["Echo package received", data])
    {:ok, data}
  end

  def payload_from_binary(_, _) do
    {:err, :invalid_payload}
  end
end
