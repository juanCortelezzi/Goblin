defmodule Server.Package do
  @moduledoc ~S"""
  Package and payload definitions for the Goblin protocol.

  ## Examples

    iex> Server.Package.from_binary(<<1, 0, 0>>)
    {:ok, {%Server.Package{version: 1, type: :echo, length: 0, payload: ""}, ""}}

    iex> Server.Package.from_binary(<<1, 0, 2, "hi">>)
    {:ok, {%Server.Package{version: 1, type: :echo, length: 2, payload: "hi"}, ""}}

  """

  use TypedStruct

  @version 1
  @package_types [:echo, :location]
  @header_size 8 + 8 + 8

  @spec version() :: integer()
  def version, do: @version

  @spec package_types() :: [atom(), ...]
  def package_types, do: @package_types

  @spec header_size() :: integer()
  def header_size, do: @header_size

  typedstruct enforce: true do
    field(:version, non_neg_integer())
    field(:type, atom())
    field(:length, non_neg_integer())
    field(:payload, binary())
  end

  defmodule Payload.Location do
    @size 8 * 12 + 64 + 64 + 64

    @spec size() :: integer()
    def size, do: @size

    typedstruct enforce: true do
      field(:id, binary())
      field(:unix_timestamp, integer())
      field(:latitude, float())
      field(:longitude, float())
    end
  end

  # From binary

  @spec from_binary(binary()) :: {:error, :invalid_version}
  def from_binary(<<version::integer, _::binary>>)
      when version != @version,
      do: {:error, :invalid_version}

  @spec from_binary(binary()) :: {:error, :invalid_version}
  def from_binary(<<@version, type::integer, _::binary>>)
      when type < 0
      when type >= length(@package_types),
      do: {:error, :invalid_type}

  @spec from_binary(binary()) :: {:error, :payload_incomplete}
  def from_binary(<<
        @version,
        _::integer,
        length::integer,
        payload::binary
      >>)
      when byte_size(payload) < length,
      do: {:error, :payload_incomplete}

  @spec from_binary(binary()) :: {:ok, {package :: t(), rest :: binary()}}
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
      package = %Server.Package{
        version: @version,
        type: type,
        length: length,
        payload: payload
      }

      {:ok, {package, rest}}
    end
  end

  @spec from_binary(binary()) :: {:error, :invalid_package}
  def from_binary(_), do: {:error, :invalid_package}

  @spec payload_from_binary(atom(), binary()) :: {:error, :invalid_payload}
  def payload_from_binary(type, _) when type not in @package_types do
    {:err, :invalid_payload}
  end

  @spec payload_from_binary(:location, binary()) :: {:ok, Payload.Location.t()}
  def payload_from_binary(
        :location,
        <<
          id::bytes-size(12),
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

  @spec payload_from_binary(:echo, binary()) :: {:ok, binary()}
  def payload_from_binary(:echo, data) do
    {:ok, data}
  end

  @spec payload_from_binary(atom(), binary()) :: {:err, :invalid_payload}
  def payload_from_binary(_, _) do
    {:err, :invalid_payload}
  end

  # To binary

  @spec to_binary(t()) :: binary()
  def to_binary(%Server.Package{
        version: version,
        type: type,
        length: length,
        payload: payload
      }) do
    payload = payload_to_binary(type, payload)
    ^length = byte_size(payload)

    type = Enum.find_index(@package_types, fn e -> e == type end)

    <<
      version::integer-size(8),
      type::integer-size(8),
      length::integer-size(8),
      payload::binary
    >>
  end

  @spec payload_to_binary(:location, Payload.Location.t()) :: binary()
  def payload_to_binary(:location, %Payload.Location{
        id: id,
        unix_timestamp: unix_timestamp,
        latitude: latitude,
        longitude: longitude
      }) do
    payload = <<
      id::bytes-size(12),
      unix_timestamp::signed-integer-size(64),
      latitude::float-size(64),
      longitude::float-size(64)
    >>

    expected_size = Payload.Location.size()
    ^expected_size = bit_size(payload)

    payload
  end

  @spec payload_to_binary(:echo, binary()) :: binary()
  def payload_to_binary(:echo, payload) do
    true = 255 >= byte_size(payload)
    payload
  end
end
