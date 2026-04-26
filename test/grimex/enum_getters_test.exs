defmodule Grimex.Util.EnumGettersTest do
  use ExUnit.Case

  defmodule Colors do
    import Grimex.Util.EnumGetters, only: [defenum: 1]

    defenum([:red, :green, :blue])
  end

  test "generates all/0 and zero-arity getters for enum values" do
    assert Colors.all() == [:red, :green, :blue]
    assert Colors.red() == :red
    assert Colors.green() == :green
    assert Colors.blue() == :blue
  end
end
