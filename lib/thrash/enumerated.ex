defmodule Thrash.Enumerated do
  @moduledoc """
  Provides a simple enumerated value module API.
  Assumes the argument to the `use` macro is a mapping from an atom key to an
  id integer.
  
  Example:
  
      defmodule MyEnum do
        use Thrash.Enumerated, %{a: 1, b: 2}
      end
  
      MyEnum.id(:a)  # => 1
      MyEnum.atom(2) # => :b
  """

  # there is probably a more idiomatic way to do a lot of this..
  defmacro __using__({hrl_file, namespace}) do
    map = Thrash.read_enum(hrl_file, namespace)
    build_enumerated(map)
  end
  defmacro __using__(map) do
    build_enumerated(map)
  end

  defp build_enumerated(map) do
    map = ensure_quoted(map)
    reversed = build_reverse(map)
    
    quote do
      def id(atom), do: unquote(map)[atom]
      def atom(id), do: unquote(reversed)[id]
    end
  end

  defp reverse_kv(kv) do
    Enum.map(kv, fn({k, v}) -> {v, k} end)
  end

  defp ensure_quoted(map) when is_map(map) do
    {:%{}, [line: __ENV__.line], Enum.into(map, [])}
  end
  defp ensure_quoted(map), do: map

  defp build_reverse({:%{}, line, kv}) do
    {:%{}, line, reverse_kv(kv)}
  end
end
