defmodule Grimex do
  # alias Grimex.Scanner
  # alias Grimex.Error

  def run_file(path) do
    path
    |> File.read!()
    |> run()
  end

  # def repl() do
  #   input = IO.gets("> ") |> String.trim()

  #   case input do
  #     "break" ->
  #       IO.puts("Breaking from REPL")

  #     text ->
  #       case run(text) do
  #         {:ok, result} ->
  #           IO.puts(result)

  #         {:error, reason, meta} ->
  #           meta = Map.merge(%{where: "", line: -1}, meta)
  #           Error.report(reason, meta)
  #       end

  #       repl()
  #   end
  # end

  defp run(text) do
    IO.puts("running #{text}")
    :ok
  end

  # TODO: working on
  # defp run2(source) do
  #   tokens = Scanner.scan(source)
  #   IO.inspect(tokens, label: "Tokens")
  #   :ok
  # end
end
