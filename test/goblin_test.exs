defmodule GoblinTest do
  use ExUnit.Case, async: false
  @host ~c"localhost"
  @port 1234

  def connect() do
    {:ok, socket} = :gen_tcp.connect(@host, @port, [:binary, active: false], 3000)
    socket
  end

  def create_big_ass_message(<<1, 0, len::integer>> <> p) when len < byte_size(p),
    do: throw("Error: we are looping indefinitively, crash and burn")

  def create_big_ass_message(<<1, 0, len::integer>> <> p = packet) when len == byte_size(p),
    do: packet

  def create_big_ass_message(<<1, 0, _>> = packet),
    do: create_big_ass_message(packet <> <<0>>)

  def create_big_ass_message(<<1, 0, _>> <> p = packet),
    do: create_big_ass_message(packet <> <<byte_size(p) + 1>>)

  test "echo packet" do
    socket = connect()
    :ok = :gen_tcp.send(socket, <<1, 0, 0>>)
    {:ok, packet} = :gen_tcp.recv(socket, 0)
    assert packet == <<1, 0, 0>>
  end

  test "big echo" do
    socket = connect()

    # bam = Big.Ass.Message
    message_one = create_big_ass_message(<<1, 0, 255, 1>>)
    message_two = create_big_ass_message(<<1, 0, 255, 2>>)
    message_three = create_big_ass_message(<<1, 0, 255, 3>>)
    message_four = create_big_ass_message(<<1, 0, 255, 4>>)

    bam =
      message_one <>
        message_two <>
        message_three <>
        message_four

    :ok = :gen_tcp.send(socket, bam)

    assert {:ok, ^message_one} = :gen_tcp.recv(socket, 0)
    assert {:ok, ^message_two} = :gen_tcp.recv(socket, 0)
    assert {:ok, ^message_three} = :gen_tcp.recv(socket, 0)
    assert {:ok, ^message_four} = :gen_tcp.recv(socket, 0)
  end
end
