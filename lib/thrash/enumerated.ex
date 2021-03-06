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

  The generated code defines a mapping from the named values, as
  atoms, to their corresponding integers:

      StatusCode.id(:ok) = 0
      StatusCode.atom(0) = :ok

  Using this module defines the following functions:

    * `map/0` - Returns the map from atom to value
    * `reverse_map/0` - Returns the map from value to atom
    * `atoms/0` - Returns the list of valid atom values
    * `values/0` - Returns the list of valid integer values
    * `id/1` - Returns the integer value for a given atom
    * `atom/1` - Returns the atom value for a given integer

  The following types are defined:

    * `atom_t/0` - Union of all valid atom values
    * `value_t/0` - Union of all valid integer values
  """

  alias Thrash.ThriftMeta
  alias Thrash.MacroHelpers

  # there is probably a more idiomatic way to do a lot of this..
  defmacro __using__(opts) do
    source_module = Keyword.get(opts, :source)
    module = MacroHelpers.determine_module_name(source_module,
                                                __CALLER__.module)
    build_enumerated(module)
  end

  defp build_enumerated(module) do
    # if you get ":enum_not_found" here, it indicates that the enum
    # you were looking for does not exist in the thrift-generated
    # erlang code
    quoted_map = module |> find_in_thrift |> ensure_quoted
    map_keys = get_keys(quoted_map)
    map_values = get_values(quoted_map)
    quoted_reversed_map = build_reverse(quoted_map)
    atoms_type = MacroHelpers.quoted_chained_or(map_keys)
    values_type = MacroHelpers.quoted_chained_or(map_values)
    require_supported = require_supported?
    quoted_map_spec = to_map_spec(quoted_map, require_supported)
    quoted_reversed_map_spec = to_map_spec(
      quoted_reversed_map,
      require_supported
    )

    quote do
      @typedoc "Valid atom values"
      @type atom_t :: unquote(atoms_type)

      @typedoc "Valid integer values"
      @type value_t :: unquote(values_type)

      @doc """
      Returns the map from valid atom values to integer values
      """
      @spec map() :: unquote(quoted_map_spec)
      def map(), do: unquote(quoted_map)

      @doc """
      Returns the reverse map from valid integer values to atom values
      """
      @spec reverse_map() :: unquote(quoted_reversed_map_spec)
      def reverse_map(), do: unquote(quoted_reversed_map)

      @doc """
      Returns the list of valid atom values
      """
      @spec atoms() :: nonempty_list(unquote(atoms_type))
      def atoms(), do: unquote(map_keys)

      @doc """
      Returns the list of valid integer values
      """
      @spec values() :: nonempty_list(unquote(values_type))
      def values(), do: unquote(map_values)

      @doc """
      Returns the integer value corresponding to the given atom
      """
      @spec id(atom_t) :: value_t
      def id(for_atom), do: unquote(quoted_map)[for_atom]

      @doc """
      Returns the atom corresponding to the given integer value
      """
      @spec atom(value_t) :: atom_t
      def atom(for_id), do: unquote(quoted_reversed_map)[for_id]
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

  defp ensure_quoted(m) when is_map(m) do
    {:%{}, [line: __ENV__.line], Enum.into(m, [])}
  end
  defp ensure_quoted(m), do: m

  defp build_reverse({:%{}, line, kv}) do
    {:%{}, line, reverse_kv(kv)}
  end

  defp get_keys({:%{}, _line, kv}) do
    Keyword.keys(kv)
  end

  defp get_values({:%{}, _line, kv}) do
    Keyword.values(kv)
  end

  # if we don't mark the keys as required, dialyzer will complain about
  # the type being a supertype with -Wunderspec enabled
  #   (Elixir 1.3+)
  defp to_map_spec({:%{}, line ,kv}, true) do
      {:%{}, line, Enum.map(kv, &required_key/1)}
  end
  # In Elixir < 1.3, require was not supported so we just pass on the map
  defp to_map_spec(quoted_map, false), do: quoted_map

  # turns %{k => v} into %{required(k) => v}, which is the Elixir equivalent of
  # #{k => v} (not required) vs #{k := v} (required)
  defp required_key({k, v}) do
    {{:required, [], [k]}, v}
  end

  def require_supported? do
    Version.match?(System.version, ">= 1.3.0")
  end
end
