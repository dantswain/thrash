defmodule Thrash.ThriftMeta do
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
  Read a struct definition from a header file.

  Uses the header name to determine the underlying module name (e.g.,
  'foo.hrl' -> ':foo') and calls struct_info.  Any namespace module is
  removed from the struct_name before calling struct_info (e.g.,
  'Foo.Bar' -> 'Bar').
  """
  @spec read_struct(String.t, atom) :: {:ok, Keyword.t} | {:error, []} 
  def read_struct(header_file, struct_name) do
    basename = Path.basename(header_file, ".hrl")
    modulename = String.to_atom(basename)
    struct_name = enum_name_string = last_part_of_atom_as_atom(struct_name)
    Thrash.StructDef.read(modulename, struct_name)
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

  defp read_record_names(header_file) do
    Record.extract_all(from: header_file) |> Dict.keys
  end

  defp ok_if_not_empty(m) when m == %{}, do: {:error, %{}}
  defp ok_if_not_empty(m) when is_map(m), do: {:ok, m}
end
