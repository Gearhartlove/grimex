defmodule Grimex.Util.EnumGetters do
  @moduledoc false

  defmacro defenum(values) do
    {values, _binding} = Code.eval_quoted(values, [], __CALLER__)

    getters =
      for value <- values do
        quote do
          def unquote(value)(), do: unquote(value)
        end
      end

    quote do
      @enum_values unquote(Macro.escape(values))

      unquote_splicing(getters)

      def all, do: @enum_values
    end
  end
end
