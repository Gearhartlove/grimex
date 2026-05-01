defmodule Grimex.Keyword do
  alias Grimex.TokenType, as: T

  @keywords %{
    "and" => T.and(),
    "class" => T.class(),
    "else" => T.else(),
    "false" => T.false(),
    "for" => T.for(),
    "fun" => T.fun(),
    "if" => T.if(),
    "nil" => T.nil(),
    "or" => T.or(),
    "print" => T.print(),
    "return" => T.return(),
    "super" => T.super(),
    "this" => T.this(),
    "true" => T.true(),
    "var" => T.var(),
    "while" => T.while()
  }

  def keywords, do: @keywords
end
