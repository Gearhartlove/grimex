defmodule Grimex.ScannerTest do
  alias Grimex.Scanner
  use ExUnit.Case

  test "scan vars" do
    source = ~s(var language = "lox";)
    {:ok, result} = Scanner.scan(source)
    expected = ["var", "language", "=", ~s("lox"), ";"]
    assert expected == result
  end
end
