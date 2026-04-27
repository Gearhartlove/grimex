defmodule Grimex.Error do
  def report(reason, %{line: line, where: where}) do
    raise "[line #{line}] Error #{where}: #{reason}"
  end
end
