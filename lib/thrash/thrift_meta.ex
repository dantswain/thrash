defmodule Thrash.ThriftMeta do
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

  defp ok_if_not_empty(m) when m == %{}, do: {:error, %{}}
  defp ok_if_not_empty(m) when is_map(m), do: {:ok, m}
end
