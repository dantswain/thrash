defmodule Thrash.ThriftMeta do
  @moduledoc false

  # Functions to access metadata from the Thrift-generated Erlang code
  # Thrash internal use only

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
  @spec read_constants(Thrift.Parser.Models.Schema.t, Module.t | nil) :: Keyword.t
  def read_constants(idl, namespace) do
    idl
    |> Map.get(:constants)
    |> thrashify_constants(idl, namespace)
    |> Enum.into(%{})
  end

  @doc """
  Convert Thrift constant names to Elixir-friendly names

  e.g., `[FOO_THING: 42], "FOO_"` -> `[thing: 42]`
  """
  @spec thrashify_constants(Keyword.t, Thrift.Parser.Models.Schema.t, Module.t | nil) :: Keyword.t
  def thrashify_constants(constants, idl, namespace) do
    Enum.map(constants,
      fn({k, v}) ->
        {thrift_to_thrash_const(k), translate_constant(v, idl, namespace)}
      end)
  end

  defp translate_constant(
    %Thrift.Parser.Models.Constant{
      type: %Thrift.Parser.Models.StructRef{referenced_type: referenced_type},
      value: value
    },
    idl,
    namespace
    ) do
    struct_module = Thrash.MacroHelpers.atom_to_elixir_module(referenced_type, namespace)
    struct = struct_module.__struct__
    struct_def = find_struct(referenced_type, idl)
    Enum.reduce(value, struct, fn({k, v}, acc) ->
      k = List.to_atom(k)
      Map.update!(acc, k, fn(_) ->
        translate_value(v, k, struct_def)
      end)
    end)
  end
  defp translate_constant(
    %Thrift.Parser.Models.Constant{
      type: {:list, ref = %Thrift.Parser.Models.StructRef{}},
      value: value
    },
    idl,
    namespace
  ) do
    Enum.map(value, fn(v) ->
      translate_constant(%Thrift.Parser.Models.Constant{type: ref, value: v}, idl, namespace)
    end)
  end
  defp translate_constant(
    %Thrift.Parser.Models.Constant{
      type: {:map, {_from_type, ref = %Thrift.Parser.Models.StructRef{}}},
      value: value
    },
    idl,
    namespace
  ) do
    Enum.map(value, fn({k, v}) ->
      {k, translate_constant(%Thrift.Parser.Models.Constant{type: ref, value: v}, idl, namespace)}
    end)
    |> Enum.into(%{})
  end
  defp translate_constant(%Thrift.Parser.Models.Constant{value: value}, _, _) do
    value
  end

  defp find_struct(name, idl) do
    Map.get(idl, :structs) |> Map.get(name)
  end

  defp translate_value(v, k, %Thrift.Parser.Models.Struct{fields: fields}) do
    field_def = find_field(fields, k)
    translate_value(v, field_def.type)
  end

  defp find_field(fields, k) do
    Enum.find(fields, fn(f) -> f.name == k end)
  end

  defp translate_value(list_string, :string) do
    List.to_string(list_string)
  end
  defp translate_value(v, _), do: v

  @doc """
  Read an enum definition from thrift IDL file

  Strips the namespace and enum name and downcases the key names.  The
  enum name is upcased before search, and only the last part of the
  atom is used (e.g., `MyApp.Things` becomes `THINGS`)
  """
  @spec read_enum(Thrift.Parser.Models.Schema.t, atom) :: map
  def read_enum(idl, enum_name) do
    enum = idl.enums
    |> Enum.find(fn({_, enum}) -> name_match?(enum.name, enum_name) end)

    if enum == nil do
      raise ArgumentError, message: "Could not find enum #{inspect enum_name}"
    else
      {_, enum} = enum
      enum.values
      |> Enum.map(fn({k, v}) ->
        {thrift_to_thrash_const(k), v}
      end)
      |> Enum.into(%{})
    end
  end

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
end
