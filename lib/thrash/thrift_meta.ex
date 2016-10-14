defmodule Thrash.ThriftMeta do
  @moduledoc false

  # Functions to access metadata from the Thrift-generated Erlang code
  # Thrash internal use only

  alias Thrash.StructDef

  @type finder :: ((String.t) -> {:ok, term} | {:error, term})

  @doc """
  Determine namespace from constants header file name

  e.g., "gen-erl/foo_constants.hrl" -> "FOO_"
  """
  @spec constants_namespace(String.t) :: String.t
  def constants_namespace(header) do
    header
    |> Path.basename(".hrl")
    |> String.replace(~r/constants$/, "")
    |> String.upcase
  end

  @doc """
  Read constants from a thrift IDL file
  """
  @spec read_constants(String.t) :: Keyword.t
  def read_constants(idl_file) do
    idl_file
    |> parse_idl
    |> Map.get(:constants)
    |> Enum.map(fn({_k, v}) ->
      {v.name, v.value}
    end)
    |> Enum.into(%{})
  end

#  @doc """
#  Convert Thrift constant names to Elixir-friendly names
#
#  e.g., `[FOO_THING: 42], "FOO_"` -> `[thing: 42]`
#  """
#  @spec thrashify_constants(Keyword.t, String.t) :: Keyword.t
#  def thrashify_constants(constants, namespace) do
#    Enum.map(constants,
#      fn({k, v}) -> {thrift_to_thrash_const(k, namespace), v} end)
#  end

#  @doc """
#  Read a struct definition from a header file.
#
#  Uses the header name to determine the underlying module name (e.g.,
#  'foo.hrl' -> ':foo') and calls struct_info.  Any namespace module is
#  removed from the struct_name before calling struct_info (e.g.,
#  'Foo.Bar' -> 'Bar').
#  """
#  @spec read_struct(String.t, atom, atom) :: {:ok, StructDef.t} | {:error, []}
#  def read_struct(header_file, struct_name, namespace) do
#    basename = Path.basename(header_file, ".hrl")
#    modulename = String.to_atom(basename)
#    struct_name = last_part_of_atom_as_atom(struct_name)
#    StructDef.read(modulename, struct_name, namespace)
#  end
#
  @doc """
  Read an enum definition from thrift IDL file

  Strips the namespace and enum name and downcases the key names.  The
  enum name is upcased before search, and only the last part of the
  atom is used (e.g., `MyApp.Things` becomes `THINGS`)
  """
  @spec read_enum(String.t, atom) :: {:ok, map} | {:error, map}
  def read_enum(idl_file, enum_name) do
    basename = Path.basename(idl_file, ".thrift")
    namespace_string = String.replace(basename, ~r/_types$/, "")
    enum_name_string = last_part_of_atom_as_string(enum_name)
    full_namespace = String.upcase(namespace_string <> "_" <>
      enum_name_string <> "_")

    idl = parse_idl(idl_file)

    enum = idl.enums
    |> Enum.find(fn({_, enum}) -> name_match?(enum.name, enum_name) end)

    if enum == nil do
      %{}
    else
      {_, enum} = enum
      enum.values
      |> Enum.map(fn({k, v}) ->
        {thrift_to_thrash_const(k, full_namespace), v}
      end)
      |> Enum.into(%{})
    end
    |> ok_if_not_empty
  end

  @doc """
  Finds a value in thrift-generated Erlang code.

  Iterates over the thrift headers, executes finder, returns the first
  value for which finder returns `{:ok, value}`.  If no result is
  found, error_value is returned.
  """
  @spec find_in_thrift(finder, term) :: term
  def find_in_thrift(finder, error_value \\ nil) do
    nil
    #headers = types_headers(erl_gen_path())
    #Enum.find_value(headers, error_value, fn(h) ->
    #  case finder.(h) do
    #    {:ok, val} -> val
    #    {:error, _} -> nil
    #  end
    #end)
  end

#  defp has_namespace?(atom, namespace) do
#    atom
#    |> Atom.to_string
#    |> String.starts_with?(namespace)
#  end
#

  defp name_match?(n1, n1), do: true
  defp name_match?(n1, n2) do
    String.downcase(last_part_of_atom_as_string(n1)) ==
      String.downcase(last_part_of_atom_as_string(n2))
  end
  
  defp thrift_to_thrash_const(k, namespace) do
    k
    |> Atom.to_string
    |> String.replace(~r/^#{namespace}/, "")
    |> String.downcase
    |> String.to_atom
  end

  defp last_part_of_atom_as_string(x) do
    x
    |> Atom.to_string
    |> String.split(".")
    |> List.last
  end

  defp last_part_of_atom_as_atom(x) do
    x
    |> last_part_of_atom_as_string
    |> String.to_atom
  end

  defp ok_if_not_empty(m) when m == %{}, do: {:error, %{}}
  defp ok_if_not_empty(m) when is_map(m), do: {:ok, m}

#  defp is_included_lib?({k, :yeah}) do
#    # with a value of :yeah, it's probably an included tag
#    # but we should be careful
#    String.match?(Atom.to_string(k), ~r/^_.*_included$/)
#  end
#  defp is_included_lib?({_k, _v}), do: false
#
#  defp is_not_included_lib?(x) do
#    !is_included_lib?(x)
#  end
#
#  defp included_tag_to_header(tag, dir) do
#    tag
#    |> Atom.to_string
#    |> String.replace(~r/^_(.*)_included$/, "\\1")
#    |> (&(Path.join(dir, &1 <> ".hrl"))).()
#  end

  defp parse_idl(idl_file) do
    Thrift.Parser.parse(File.read!(idl_file))
  end
end
