defmodule Thrash.ThriftMeta do
  @moduledoc """
  Functions to access metadata from the Thrift-generated Erlang code
  """

  @type finder :: ((String.t) -> {:ok, term} | {:error, term})

  @doc """
  Returns the path of the thrift-generated erlang files.

  By default this is 'src/erl-gen'.  You can override it with the
  Application env path `:thrash`/`:erl_gen_path`
  """
  @spec erl_gen_path() :: String.t
  def erl_gen_path() do
    Application.get_env(:thrash, :erl_gen_path, "src/gen-erl")
    |> Path.expand
  end

  @doc """
  Returns a list of erlang header files matching *_types.hrl in any
  subdirectory of root_path (usually erl_gen_path/0).
  """
  @spec types_headers(String.t) :: [String.t]
  def types_headers(root_path) do
    root_path
    |> Path.join("**/*_types.hrl")
    |> Path.wildcard
  end

  @doc """
  Returns a list of erlang header files matching *_types.hrl in any
  subdirectory of root_path (usually erl_gen_path/0).
  """
  @spec constants_headers(String.t) :: [String.t]
  def constants_headers(root_path) do
    root_path
    |> Path.join("**/*_constants.hrl")
    |> Path.wildcard
  end

  @doc """
  Determine namespace from constants header file name

  e.g., "gen-erl/foo_constants.hrl" -> "FOO_"
  """
  @spec constants_namespace(String.t) :: String.t
  def constants_namespace(header) do
    Path.basename(header, ".hrl")
    |> String.replace(~r/constants$/, "")
    |> String.upcase
  end

  @doc """
  Read the `-define`d constants from a thrift-generated header file.

  Mostly a passthrough to Quaff.Constants.get_constants, but strips
  out some of the metadata that it returns.
  """
  @spec read_constants(String.t) :: Keyword.t
  def read_constants(header_file) do
    basename = Path.basename(header_file, ".hrl")
    included_tag = String.to_atom("_" <> basename <> "_included")
    meta_constants = [:MODULE_STRING, :FILE, :MODULE, included_tag]
    Quaff.Constants.get_constants(header_file, [])
    |> Enum.filter(fn({k, _v}) ->
      !Enum.member?(meta_constants, k)
    end)
  end

  @doc """
  Convert Thrift constant names to Elixir-friendly names

  e.g., `[FOO_THING: 42], "FOO_"` -> `[thing: 42]`
  """
  @spec thrashify_constants(Keyword.t, String.t) :: Keyword.t
  def thrashify_constants(constants, namespace) do
    Enum.map(constants, fn({k, v}) -> {thrift_to_thrash_const(k, namespace), v} end)
  end

  @doc """
  Read constants from a header file, exclude constants from included headers
  """
  @spec read_constants_exclusive(String.t) :: Keyword.t
  def read_constants_exclusive(header_file) do
    constants = read_constants(header_file)
    |> Enum.into(MapSet.new)

    included = determine_included_libs(constants, header_file)
    included_constants = Enum.map(included,
      fn(incl) -> read_constants(incl) end)
    |> List.flatten
    |> Enum.uniq
    |> Enum.into(MapSet.new)

    MapSet.difference(constants, included_constants)
    |> Enum.into([])
    |> Enum.filter(&is_not_included_lib?/1)
  end

  def determine_included_libs(constants, header_file) do
    dir = Path.dirname(header_file)
    Enum.filter(constants, fn({constant, value}) ->
      is_included_lib?({constant, value})
    end)
    |> Enum.map(fn({k, _v}) ->
      included_tag_to_header(k, dir)
    end)
  end

  @doc """
  Read a struct definition from a header file.

  Uses the header name to determine the underlying module name (e.g.,
  'foo.hrl' -> ':foo') and calls struct_info.  Any namespace module is
  removed from the struct_name before calling struct_info (e.g.,
  'Foo.Bar' -> 'Bar').
  """
  @spec read_struct(String.t, atom, atom) :: {:ok, Keyword.t} | {:error, []} 
  def read_struct(header_file, struct_name, namespace) do
    basename = Path.basename(header_file, ".hrl")
    modulename = String.to_atom(basename)
    struct_name = last_part_of_atom_as_atom(struct_name)
    Thrash.StructDef.read(modulename, struct_name, namespace)
  end

  @doc """
  Read an enum definition from a header file.

  Strips the namespace and enum name and downcases the key names.  The
  enum name is upcased before search, and only the last part of the
  atom is used (e.g., `MyApp.Things` becomes `THINGS`)
  """
  @spec read_enum(String.t, atom) :: {:ok, map} | {:error, map}
  def read_enum(header_file, enum_name) do
    basename = Path.basename(header_file, ".hrl")
    namespace_string = String.replace(basename, ~r/_types$/, "")
    enum_name_string = last_part_of_atom_as_string(enum_name)
    full_namespace = (namespace_string <> "_" <> enum_name_string <> "_") |> String.upcase
    
    read_constants(header_file)
    |> Enum.filter(fn({k, _v}) -> has_namespace?(k, full_namespace) end)
    |> Enum.map(fn({k, v}) -> {thrift_to_thrash_const(k, full_namespace), v} end)
    |> Enum.into(%{})
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
    headers = types_headers(erl_gen_path())
    Enum.find_value(headers, error_value, fn(h) ->
      case finder.(h) do
        {:ok, val} -> val
        {:error, _} -> nil
      end
    end)
  end

  defp has_namespace?(atom, namespace) do
    Atom.to_string(atom)
    |> String.starts_with?(namespace)
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

  defp is_included_lib?({k, :yeah}) do
    # with a value of :yeah, it's probably an included tag
    # but we should be careful
    String.match?(Atom.to_string(k), ~r/^_.*_included$/)
  end
  defp is_included_lib?({_k, _v}), do: false

  defp is_not_included_lib?(x) do
    !is_included_lib?(x)
  end

  defp included_tag_to_header(tag, dir) do
    Atom.to_string(tag)
    |> String.replace(~r/^_(.*)_included$/, "\\1")
    |> (&(Path.join(dir, &1 <> ".hrl"))).()
  end
end
