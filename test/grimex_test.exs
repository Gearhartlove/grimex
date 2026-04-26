defmodule GrimexTest do
  use ExUnit.Case
  doctest Grimex

  test "greets the world" do
    assert Grimex.hello() == :world
  end
end
