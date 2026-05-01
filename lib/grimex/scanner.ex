defmodule Grimex.Scanner do
  alias Grimex.TokenType
  alias Grimex.Token
  alias Grimex.Error

  import Grimex.Guards

  defstruct original: [], source: [], tokens: [], start: 0, current: 0, line: 1

  def new(original), do: %__MODULE__{source: original, original: original}

  def scan(source) do
    source
    |> String.graphemes()
    |> new()
    |> scan_tokens()
  end

  defp scan_tokens(%__MODULE__{source: []} = scanner) do
    scanner
    |> add_token(TokenType.eof())
    |> then(fn scanner ->
      %{scanner | tokens: Enum.reverse(scanner.tokens)}
    end)
    |> then(fn scanner ->
      {:ok, scanner.tokens}
    end)
  end

  defp scan_tokens(%__MODULE__{} = scanner) do
    scanner
    |> start_token()
    |> scan_token()
    |> scan_tokens()
  end

  defp scan_token(%__MODULE__{} = scanner) do
    {char, scanner} = advance(scanner)

    case char do
      "!" ->
        case match(scanner, "=") do
          {true, scanner} -> add_token(scanner, TokenType.bang_equal())
          {false, scanner} -> add_token(scanner, TokenType.bang())
        end

      "=" ->
        case match(scanner, "=") do
          {true, scanner} -> add_token(scanner, TokenType.equal_equal())
          {false, scanner} -> add_token(scanner, TokenType.equal())
        end

      "<" ->
        case match(scanner, "=") do
          {true, scanner} -> add_token(scanner, TokenType.less_equal())
          {false, scanner} -> add_token(scanner, TokenType.less())
        end

      ">" ->
        case match(scanner, "=") do
          {true, scanner} -> add_token(scanner, TokenType.greater_equal())
          {false, scanner} -> add_token(scanner, TokenType.greater())
        end

      "/" ->
        case match(scanner, "/") do
          {true, scanner} -> skip_comment(scanner)
          {false, scanner} -> add_token(scanner, TokenType.slash())
        end

      "(" ->
        add_token(scanner, TokenType.left_paren())

      ")" ->
        add_token(scanner, TokenType.right_paren())

      "{" ->
        add_token(scanner, TokenType.left_brace())

      "}" ->
        add_token(scanner, TokenType.right_brace())

      "," ->
        add_token(scanner, TokenType.comma())

      "." ->
        add_token(scanner, TokenType.dot())

      "-" ->
        case peek(scanner, fn c -> c >= "0" and c <= "9" end) do
          {true, scanner} ->
            number(scanner, negative?: true)

          {false, scanner} ->
            add_token(scanner, TokenType.minus())
        end

      "+" ->
        add_token(scanner, TokenType.plus())

      ";" ->
        add_token(scanner, TokenType.semicolon())

      "*" ->
        add_token(scanner, TokenType.star())

      "\n" ->
        %{scanner | line: scanner.line + 1}

      "\"" ->
        string(scanner, [])

      c when c >= "0" and c <= "9" ->
        number(scanner, c)

      c when is_alphanumeric_char(c) ->
        identifier_or_keyword(scanner, c)

      " " ->
        scanner

      "\r" ->
        scanner

      "\t" ->
        scanner
    end
  end

  defp start_token(%__MODULE__{current: current} = scanner) do
    %{scanner | start: current}
  end

  defp advance(%__MODULE__{source: [char | rest], current: current} = scanner) do
    {char, %{scanner | source: rest, current: current + 1}}
  end

  defp peek(%__MODULE__{source: [c | _] = source, current: current} = scanner, matcher)
       when is_function(matcher) do
    case matcher.(c) do
      true ->
        {true, %{scanner | source: source, current: current}}

      false ->
        {false, scanner}
    end
  end

  defp peek(%__MODULE__{source: [c | _] = source, current: current} = scanner, c) do
    {true, %{scanner | source: source, current: current}}
  end

  defp peek(scanner, _expected) do
    {false, scanner}
  end

  defp match(%__MODULE__{source: [c | rest], current: current} = scanner, matcher)
       when is_function(matcher) do
    case matcher.(c) do
      true ->
        {true, %{scanner | source: rest, current: current + 1}}

      false ->
        {false, scanner}
    end
  end

  defp match(%__MODULE__{source: [expected | rest], current: current} = scanner, expected) do
    {true, %{scanner | source: rest, current: current + 1}}
  end

  defp match(%__MODULE__{} = scanner, _expected) do
    {false, scanner}
  end

  defp skip_comment(%__MODULE__{source: source, current: current} = scanner) do
    {comment, rest} = Enum.split_while(source, &(&1 != "\n"))

    %{scanner | source: rest, current: current + length(comment)}
  end

  def string(%__MODULE__{source: [], line: line, start: start} = _scanner, _acc) do
    Error.report("Unterminated String", %{line: line, where: start})
  end

  def string(%__MODULE__{source: ["\"" | rest], current: current} = scanner, acc) do
    value = acc |> Enum.reverse() |> Enum.join()

    scanner
    |> Map.merge(%{source: rest, current: current + 1})
    |> add_token(TokenType.string(), value)
  end

  def string(%__MODULE__{source: ["\n" | rest], current: current, line: line} = scanner, acc) do
    scanner
    |> Map.merge(%{source: rest, current: current + 1, line: line + 1})
    |> string(["\n" | acc])
  end

  def string(%__MODULE__{} = scanner, acc) do
    {c, scanner} = advance(scanner)
    string(scanner, [c | acc])
  end

  def number(scanner, negative?: true) do
    number(scanner, %{float?: false, vals: [], negative?: true})
  end

  def number(scanner, c) when is_binary(c) do
    number(scanner, %{float?: false, vals: [c]})
  end

  def number(
        %__MODULE__{source: []} = scanner,
        acc
      ) do
    add_number_token(scanner, acc, [])
  end

  def number(%__MODULE__{source: [c | rest]} = scanner, acc)
      when (c < "0" or c > "9") and c != "." do
    add_number_token(scanner, acc, rest)
  end

  def number(%__MODULE__{} = scanner, %{float?: float?, vals: vals} = acc) do
    {c, scanner} = advance(scanner)

    case c do
      "." ->
        case float? do
          false ->
            number(scanner, %{acc | float?: true, vals: [c | vals]})

          true ->
            Error.report("Double '.' specified in float", %{
              line: scanner.line,
              where: scanner.current
            })
        end

      _ ->
        number(scanner, %{acc | vals: [c | vals]})
    end
  end

  def identifier_or_keyword(scanner, c) when is_alphanumeric_char(c),
    do: identifier_or_keyword(scanner, [c])

  def identifier_or_keyword(%__MODULE__{} = scanner, acc) do
    # do I want to peek here?
    {char, %__MODULE__{start: start, current: current, original: original} = scanner} =
      advance(scanner)

    case char do
      c when is_alphanumeric_char(c) ->
        identifier_or_keyword(scanner, [c | acc])

      _ ->
        nil
    end
  end

  defp add_number_token(
         %__MODULE__{current: current} = scanner,
         %{float?: float?, vals: vals} = acc,
         source
       ) do
    negative? = Map.get(acc, :negative?, false)

    val =
      vals
      |> Enum.reverse()
      |> Enum.join()
      |> then(fn val ->
        case float? do
          true -> val |> String.to_float()
          false -> val |> String.to_integer()
        end
      end)
      |> then(fn val ->
        case negative? do
          true -> val * -1
          false -> val
        end
      end)

    scanner
    |> Map.merge(%{source: source, current: current})
    |> add_token(TokenType.number(), val)
  end

  defp add_token(%__MODULE__{} = scanner, type),
    do: add_token(scanner, type, nil)

  defp add_token(%__MODULE__{tokens: tokens, line: line} = scanner, :eof, literal) do
    token = Token.new(TokenType.eof(), nil, literal, line)
    %{scanner | tokens: [token | tokens]}
  end

  defp add_token(%__MODULE__{tokens: tokens, line: line} = scanner, type, literal) do
    token = Token.new(type, lexeme(scanner), literal, line)
    %{scanner | tokens: [token | tokens]}
  end

  defp lexeme(%__MODULE__{original: original, start: start, current: current}) do
    original
    |> Enum.slice(start, current - start)
    |> Enum.join()
  end
end
