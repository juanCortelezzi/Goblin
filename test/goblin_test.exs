defmodule GoblinTest do
  use ExUnit.Case, async: false

  test "sanity" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 1234, active: false)
    IO.inspect(socket)
    assert true
  end
end
