defmodule Grimex.Scanner2 do
  alias Grimex.TokenType
  alias Grimex.Token
  alias Grimex.Error

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
        add_token(scanner, TokenType.minus())

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
