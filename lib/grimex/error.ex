defmodule Grimex.Error do
  def report(reason, %{line: line, where: where}) do
    IO.puts(:stderr, "[line #{line}] Error #{where}: #{reason}")
  end
end
