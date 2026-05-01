defmodule Grimex.Guards do
  defguard is_alphanumeric_char(c)
           when c in ?0..?9 or c in ?A..?Z or c in ?a..?z
end
