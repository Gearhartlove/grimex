defmodule Grimex.Scanner do
  alias Grimex.TokenType
  alias Grimex.Token
  alias Grimex.Error

  def scan([], tokens, _meta), do: Enum.filter(Enum.reverse(tokens) ++ [TokenType.eof()], & &1)

  def scan(
        char_list,
        tokens,
        meta
      ) do
    {token, rest} = scan_token(char_list)
    scan(rest, [token | tokens], meta)
  end

  def scan(source),
    do: scan(String.graphemes(source), [], %{start: 0, current: 0, line: 1, source: source})

  # note: no way to increment the rest more here
  # I could return the rest, but it looks gronky
  # DOUBLES
  defp scan_token(["!", "=" | rest]), do: {TokenType.bang_equal(), rest}
  defp scan_token(["=", "=" | rest]), do: {TokenType.equal_equal(), rest}
  defp scan_token(["<", "=" | rest]), do: {TokenType.less_equal(), rest}
  defp scan_token([">", "=" | rest]), do: {TokenType.greater_equal(), rest}

  defp scan_token(["/", "/" | rest]) do
    {_before, rest} = Enum.split_while(rest, &(&1 != "\n"))
    {nil, rest}
  end

  # SINGLES
  defp scan_token(["!" | rest]), do: {TokenType.bang(), rest}
  defp scan_token(["(" | rest]), do: {TokenType.left_paren(), rest}
  defp scan_token([")" | rest]), do: {TokenType.right_paren(), rest}
  defp scan_token(["{" | rest]), do: {TokenType.left_brace(), rest}
  defp scan_token(["}" | rest]), do: {TokenType.right_brace(), rest}
  defp scan_token(["," | rest]), do: {TokenType.comma(), rest}
  defp scan_token(["." | rest]), do: {TokenType.dot(), rest}
  defp scan_token(["-" | rest]), do: {TokenType.minus(), rest}
  defp scan_token(["+" | rest]), do: {TokenType.plus(), rest}
  defp scan_token([";" | rest]), do: {TokenType.semicolon(), rest}
  defp scan_token(["*" | rest]), do: {TokenType.star(), rest}
  defp scan_token(["=" | rest]), do: {TokenType.equal(), rest}
  defp scan_token(["<" | rest]), do: {TokenType.less(), rest}
  defp scan_token([">" | rest]), do: {TokenType.greater(), rest}
  defp scan_token(["/" | rest]), do: {TokenType.slash(), rest}
  defp scan_token([" " | rest]), do: {nil, rest}
  defp scan_token(["\r" | rest]), do: {nil, rest}
  defp scan_token(["\t" | rest]), do: {nil, rest}
  # TODO: increment the line we are on 
  defp scan_token(["\n" | rest]), do: {nil, rest}

  defp scan_token(["\"" | rest]) do
    case Enum.split_while(rest, &(&1 != "\"")) do
      {_before, []} ->
        # NOTE: unsure if this is the right where here
        Error.report("Unterminated string.", %{line: -1, where: ""})

      {before, ["\"" | rest]} ->
        # {TokenType.string(), rest}
        {Token.new(TokenType.string(), before, before, -1), rest}
    end
  end

  defp scan_token([token | _rest]) do
    raise "Unexpected token '#{token}'"
  end

  def token(type, meta), do: token(type, nil, meta)

  def token(type, literal, meta) do
    start = Map.fetch!(meta, :start)
    current = Map.fetch!(meta, :current)
    line = Map.fetch!(meta, :line)
    source = Map.fetch!(meta, :source)

    # TODO: check for off by 1
    text = String.slice(source, start, current - start)

    Token.new(type, text, literal, line)
  end
end
