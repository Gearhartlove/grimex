defmodule Grimex.ScannerTest do
  alias Grimex.Scanner
  alias Grimex.Token
  alias Grimex.TokenType
  use ExUnit.Case

  describe "Number Scanning" do
    test "single digit" do
      expected =
        {:ok, [Token.new(TokenType.number(), "1", 1, 1), Token.new(TokenType.eof(), nil, nil, 1)]}

      assert expected == Scanner.scan("1")
    end

    test "double digit" do
      expected =
        {:ok,
         [Token.new(TokenType.number(), "12", 12, 1), Token.new(TokenType.eof(), nil, nil, 1)]}

      assert expected == Scanner.scan("12")
    end

    test "N digit" do
      0..100_000
      |> Enum.map(fn n ->
        expected =
          {:ok,
           [
             Token.new(TokenType.number(), Integer.to_string(n), n, 1),
             Token.new(TokenType.eof(), nil, nil, 1)
           ]}

        assert expected == Scanner.scan("#{n}")
      end)
    end

    test "single digit float" do
      expected =
        {:ok,
         [Token.new(TokenType.number(), "0.1", 0.1, 1), Token.new(TokenType.eof(), nil, nil, 1)]}

      assert expected == Scanner.scan("0.1")
    end

    test "double digit float" do
      expected =
        {:ok,
         [Token.new(TokenType.number(), "0.12", 0.12, 1), Token.new(TokenType.eof(), nil, nil, 1)]}

      assert expected == Scanner.scan("0.12")
    end

    test "N digit float" do
      0..100_000
      |> Enum.map(fn n ->
        expected =
          {:ok,
           [
             Token.new(TokenType.number(), "0.#{n}", String.to_float("0.#{n}"), 1),
             Token.new(TokenType.eof(), nil, nil, 1)
           ]}

        assert expected == Scanner.scan("0.#{n}")
      end)
    end
  end
end
