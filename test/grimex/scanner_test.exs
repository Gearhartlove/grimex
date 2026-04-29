defmodule Grimex.ScannerTest do
  alias Grimex.Scanner
  alias Grimex.Token
  alias Grimex.TokenType
  use ExUnit.Case
  use ExUnitProperties

  describe "Number Scanning" do
    property "parse arbitrary integer" do
      check all(num <- integer(-1_000_000..1_000_000)) do
        num_parsed = Integer.to_string(num)

        expected =
          {:ok,
           [
             Token.new(TokenType.number(), num_parsed, num, 1),
             Token.new(TokenType.eof(), nil, nil, 1)
           ]}

        assert expected == Scanner.scan(num_parsed)
      end
    end

    property "parse arbitrary float" do
      check all(num <- float(min: -1_000_000, max: 1_000_000)) do
        num_parsed = :erlang.float_to_binary(num, [:compact, decimals: 100])

        expected =
          {:ok,
           [
             Token.new(TokenType.number(), num_parsed, num, 1),
             Token.new(TokenType.eof(), nil, nil, 1)
           ]}

        assert expected == Scanner.scan(num_parsed)
      end
    end
  end
end
