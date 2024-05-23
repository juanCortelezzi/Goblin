defmodule GoblinServer.Package do
  @moduledoc ~S"""
  Package and payload definitions for the Goblin protocol.

  ## Examples

    iex> GoblinServer.Package.from_binary(<<1, 0, 0>>)
    {:ok, {%GoblinServer.Package{version: 1, type: :echo, length: 0, payload: ""}, ""}}

    iex> GoblinServer.Package.from_binary(<<1, 0, 2, "hi">>)
    {:ok, {%GoblinServer.Package{version: 1, type: :echo, length: 2, payload: "hi"}, ""}}

  """
  defstruct [:version, :type, :length, :payload]

  defmodule Payload.Location do
    defstruct [:id, :unix_timestamp, :latitude, :longitude]
  end

  @version 1
  @package_types [:echo, :location]

  def from_binary(<<version::integer>> <> _)
      when version != @version,
      do: {:error, :invalid_version}

  def from_binary(<<@version, type::integer>> <> _)
      when type < 0
      when type >= length(@package_types),
      do: {:error, :invalid_type}

  def from_binary(<<
        @version,
        _::integer,
        length::integer,
        payload::binary
      >>)
      when byte_size(payload) < length,
      do: {:error, :payload_incomplete}

  # BEu8 is the default for integer
  def from_binary(
        <<
          @version,
          type::integer,
          length::integer,
          payload::binary-size(length)
        >> <> rest
      ) do
    type = Enum.at(@package_types, type)

    with {:ok, payload} <- payload_from_binary(type, payload) do
      package = %GoblinServer.Package{
        version: @version,
        type: type,
        length: length,
        payload: payload
      }

      {:ok, {package, rest}}
    end
  end

  def from_binary(_), do: {:error, :invalid_package}

  def to_binary(%GoblinServer.Package{
        version: version,
        type: type,
        length: length,
        payload: payload
      }) do
    payload = payload_to_binary(type, payload)
    type = Enum.find_index(@package_types, fn e -> e == type end)

    package = <<
      version::integer-size(8),
      type::integer-size(8),
      length::integer-size(8),
      payload::binary
    >>

    # Ensure the length is correct (sanity check)
    ^length = byte_size(payload)

    package
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
    location = %Payload.Location{
      id: id,
      unix_timestamp: unix_timestamp,
      latitude: latitude,
      longitude: longitude
    }

    {:ok, location}
  end

  def payload_from_binary(:echo, data) do
    {:ok, data}
  end

  def payload_from_binary(_, _) do
    {:err, :invalid_payload}
  end

  # Payload to binary

  def payload_to_binary(:location, %GoblinServer.Package.Payload.Location{
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

    payload
  end

  def payload_to_binary(:echo, payload) do
    payload
  end
end
