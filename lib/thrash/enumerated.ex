defmodule Thrash.Enumerated do
  # Provides a simple enumerated value module API.
  # Assumes the argument to the `use` macro is a mapping from an atom key to an
  # id integer.
  # 
  # Example:
  #
  #     defmodule MyEnum do
  #       use Thrash.Enumerated, %{a: 1, b: 2}
  #     end
  #
  #     MyEnum.id(:a)  # => 1
  #     MyEnum.atom(2) # => :b
  defmacro __using__(map) do

    # there is probably a more idiomatic way to do this..
    {:%{}, line, kv} = map
    reversed_kv = reverse_kv(kv)
    reversed = {:%{}, line, reversed_kv}

    quote do
      def id(atom), do: unquote(map)[atom]
      def atom(id), do: unquote(reversed)[id]
    end
  end

  defp reverse_kv(kv) do
    Enum.map(kv, fn({k, v}) -> {v, k} end)
  end
end
