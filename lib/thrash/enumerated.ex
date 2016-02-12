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
  override the name of the enum by passing it to the `use` call:

    defmodule MyApp.Codes do
      use Thrash.Enumerated, StatusCodes
    end
  """

  alias Thrash.ThriftMeta

  # there is probably a more idiomatic way to do a lot of this..
  defmacro __using__(override_module) do
    module = determine_module_name(override_module, __CALLER__)
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
    headers = ThriftMeta.types_headers(ThriftMeta.erl_gen_path())
    Enum.find_value(headers, :enum_not_found, fn(h) ->
      case ThriftMeta.read_enum(h, modname) do
        {:ok, enum} -> enum
        {:error, _} -> nil
      end
    end)
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

  defp determine_module_name([], caller) do
    get_caller_module_name(caller)
  end
  defp determine_module_name({_, _, [module]}, _) do
    module
  end

  defp get_caller_module_name(caller) do
    Macro.expand(quote do
                   __MODULE__
    end, caller)
  end
end
