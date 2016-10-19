defmodule Thrash.Constants do
  @moduledoc """
  Creates functions for the constants defined in your Thrift IDL.

  Suppose we have, in a Thrift file:

      // in thrift file
      const i32 MAX_THINGS = 42
      const i32 MAGIC_NUMBER = 99

  Bring these values into your Elixir app by doing

      defmodule MyApp.Constants
        use Thrash.Constants
      end

  This will define functions `MyApp.Constants.max_things/0` and
  `MyApp.Constants.magic_number/0`.
  """

  alias Thrash.ThriftMeta

  defmacro __using__(_opts \\ []) do
    caller = __CALLER__.module
    caller_namespace = Thrash.MacroHelpers.find_namespace(caller)

    constants = ThriftMeta.parse_idl
    |> ThriftMeta.read_constants(caller_namespace)

    Enum.map(constants, fn({k, v}) ->
      defconst(k, ensure_quoted(v))
    end)
  end

  defp ensure_quoted(s = %{__struct__: struct_name}) do
    {
      :%,
      [line: __ENV__.line],
      [
        {:__aliases__, [alias: false], [ThriftMeta.last_part_of_atom_as_atom(struct_name)]},
        {:%{}, [line: __ENV__.line], s |> Map.from_struct |> Enum.into([]) |> Enum.map(&ensure_quoted/1)}
      ]
    }
  end
  defp ensure_quoted(m) when is_map(m) do
    {:%{}, [line: __ENV__.line], Enum.into(m, [])}
  end
  defp ensure_quoted(m), do: m

  defp defconst(k, v) do
    quote do
      def unquote(k)() do
        unquote(v)
      end
    end
  end
end
