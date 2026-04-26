defmodule Grimex.TokenTypeTest do
  use ExUnit.Case

  alias Grimex.TokenType

  test "generates a getter for each token type" do
    for token_type <- TokenType.all() do
      assert token_type == apply(TokenType, token_type, [])
    end
  end
end
