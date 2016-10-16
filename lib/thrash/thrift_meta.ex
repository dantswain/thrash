defmodule Thrash.ThriftMeta do
  @moduledoc false

  # Functions to access metadata from the Thrift-generated Erlang code
  # Thrash internal use only

  alias Thrash.StructDef

  @type finder :: ((String.t) -> {:ok, term} | {:error, term})

  def parse_idl do
    parse_idl(Application.get_env(:thrash, :idl_files))
  end

  def parse_idl(junk) when junk == [] or is_nil(junk) do
    raise ArgumentError, message: "No IDL files found."
  end
  def parse_idl(idl_files) do
    idl_files
    |> Enum.reduce(%Thrift.Parser.Models.Schema{}, fn(path, full_schema) ->
      file_idl = Thrift.Parser.parse(File.read!(path))
      merge_idls(full_schema, file_idl)
    end)
  end

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
  @spec read_constants(Thrift.Parser.Models.Schema.t) :: Keyword.t
  def read_constants(idl) do
    idl
    |> Map.get(:constants)
    |> Enum.map(fn({_k, v}) ->
      {v.name, v.value}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Convert Thrift constant names to Elixir-friendly names

  e.g., `[FOO_THING: 42], "FOO_"` -> `[thing: 42]`
  """
  @spec thrashify_constants(Keyword.t) :: Keyword.t
  def thrashify_constants(constants) do
    Enum.map(constants,
      fn({k, v}) -> {thrift_to_thrash_const(k), v.value} end)
  end

  @doc """
  Read an enum definition from thrift IDL file

  Strips the namespace and enum name and downcases the key names.  The
  enum name is upcased before search, and only the last part of the
  atom is used (e.g., `MyApp.Things` becomes `THINGS`)
  """
  @spec read_enum(Thrift.Parser.Models.Schema.t, atom)
  :: {:ok, map} | {:error, map}
  def read_enum(idl, enum_name) do
    enum = idl.enums
    |> Enum.find(fn({_, enum}) -> name_match?(enum.name, enum_name) end)

    if enum == nil do
      %{}
    else
      {_, enum} = enum
      enum.values
      |> Enum.map(fn({k, v}) ->
        {thrift_to_thrash_const(k), v}
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
  
  defp thrift_to_thrash_const(k) do
    k
    |> Atom.to_string
    |> String.downcase
    |> String.to_atom
  end

  defp last_part_of_atom_as_string(x) do
    x
    |> Atom.to_string
    |> String.split(".")
    |> List.last
  end

  def last_part_of_atom_as_atom(x) do
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

  defp merge_idls(
    accum = %Thrift.Parser.Models.Schema{},
    el = %Thrift.Parser.Models.Schema{}) do
    %{accum |
      constants: merge_maps(accum.constants, el.constants),
      enums: merge_maps(accum.enums, el.enums),
      exceptions: merge_maps(accum.exceptions, el.exceptions),
      includes: merge_includes(accum.includes, el.includes),
      namespaces: merge_maps(accum.namespaces, el.namespaces),
      services: merge_maps(accum.services, el.services),
      structs: merge_maps(accum.structs, el.structs),
      thrift_namespace: merge_namespaces(accum.thrift_namespace, el.thrift_namespace),
      typedefs: merge_maps(accum.typedefs, el.typedefs),
      unions: merge_maps(accum.unions, el.unions)
    }
  end

  defp merge_maps(m1, m2) do
    Map.merge(m1, m2)
  end

  defp merge_includes(i1, i2) do
    i1 ++ i2
  end

  defp merge_namespaces(nil, nil), do: nil
  defp merge_namespaces(s1, s2) do
    IO.puts("NAMESPACES: #{inspect s1} #{inspect s2}")
    s2
  end
end
