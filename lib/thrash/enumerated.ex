defmodule Thrash.Enumerated do
  @moduledoc """
  Builds an enumerated value module from thrift-generated erlang code.

  Suppose you have thrift file with enumerated values:

    // in thrift file
    enum StatusCodes {
      OK = 0
      ERROR = 1
    }

  Bring these enumerated values into your Elixir app by doing

    defmodule MyApp.StatusCodes do
      use Thrash.Enumerated
    end

  As long as the name of your module ends with 'StatusCodes', Thrash
  should find the enumerated values automatically.  You can manually
  override the name of the source enum by passing it to the `use` call:

    defmodule MyApp.Codes do
      use Thrash.Enumerated, source: StatusCodes
    end
  """

  alias Thrash.ThriftMeta
  alias Thrash.MacroHelpers

  # there is probably a more idiomatic way to do a lot of this..
  defmacro __using__(opts) do
    source_module = Keyword.get(opts, :source)
    module = MacroHelpers.determine_module_name(source_module, __CALLER__.module)
    build_enumerated(module)
  end

  def build_enumerated(module) do
    # if you get ":enum_not_found" here, it indicates that the enum
    # you were looking for does not exist in the thrift-generated
    # erlang code
    map = find_in_thrift(module) |> ensure_quoted
    reversed = build_reverse(map)
    
    quote do
      def map(), do: unquote(map)
      def reverse_map(), do: unquote(reversed)
      def id(atom), do: unquote(map)[atom]
      def atom(id), do: unquote(reversed)[id]
    end
  end

  defp find_in_thrift(modname) do
    ThriftMeta.find_in_thrift(fn(h) ->
      ThriftMeta.read_enum(h, modname)
    end, :enum_not_found)
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
