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
  alias Thrash.MacroHelpers

  defmacro __using__(_opts \\ []) do
    caller = __CALLER__.module
    caller_namespace = Thrash.MacroHelpers.find_namespace(caller)

    constants = ThriftMeta.parse_idl
    |> ThriftMeta.read_constants(caller_namespace)

    Enum.map(constants, fn({k, v}) ->
      defconst(k, Macro.escape(v))
    end)
  end

  defp defconst(k, v) do
    quote do
      def unquote(k)() do
        unquote(v)
      end
    end
  end
end
