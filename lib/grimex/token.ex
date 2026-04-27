defmodule Grimex.Token do
  defstruct [:type, :lexeme, :literal, :line]

  defimpl String.Chars do
    def to_string(%Grimex.Token{type: type, lexeme: lexeme, literal: literal}) do
      "#{type} #{lexeme} #{literal}"
    end
  end

  def new(type, lexeme, literal, line) do
    %__MODULE__{
      type: type,
      lexeme: lexeme,
      literal: literal,
      line: line
    }
  end
end
