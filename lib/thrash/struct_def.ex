defmodule Thrash.StructDef do
  @moduledoc false

  # Thrash's translation layer between the Thrift IDL and the generated
  # Elixir code.
  # Thrash internal use only

  defmodule Field do
    @moduledoc false
    # Metadata about a struct field

    alias Thrash.Type

    defstruct(id: nil, required: nil, type: nil, name: nil, default: nil)
    @type t :: %Field{id: integer,
                      required: boolean,
                      type: Type.type_specifier,
                      name: atom,
                      default: term}

    def finalizer do
      %Field{name: :final}
    end
  end

  @type t :: [Field.t]
  @type thrift_field :: {id :: integer,
                         required :: boolean,
                         type :: atom,
                         name :: atom,
                         default :: term}

  alias Thrash.MacroHelpers
  alias Thrash.IDL

  @spec find_in_thrift(atom, MacroHelpers.namespace) :: t
  def find_in_thrift(modulename, namespace) do
    idl = IDL.parse
    modulename = Thrash.ThriftMeta.last_part_of_atom_as_atom(modulename)
    {:ok, struct_def} = read(idl, modulename, namespace)
    struct_def
  end

  @spec read(Thrift.Parser.Models.Schema.t, atom, MacroHelpers.namespace) :: {:ok, t} | {:error, []}
  def read(idl, struct_name, namespace) do
    struct_name
    |> try_reading_struct_from(idl)
    |> maybe_do(fn(struct_info) -> from_thrift_struct(namespace, struct_info) end)
  end

  def from_thrift_struct(namespace, %Thrift.Parser.Models.Struct{fields: fields}) do
    Enum.map(fields, fn(field) ->
      %Field{id: field.id,
             required: undefined_to_nil(field.required),
             type: translate_type(field.type, namespace),
             name: field.name,
             default: translate_default(field.type, field.default, namespace)}
    end)
  end

  @spec from_struct_info(MacroHelpers.namespace, {:struct, [thrift_field]}) :: t
  def from_struct_info(namespace, {:struct, fields}) do
    Enum.map(fields, fn({id, required, type, name, default}) ->
      %Field{id: id,
             required: undefined_to_nil(required),
             type: translate_type(type, namespace),
             name: name,
             default: translate_default(type, default, namespace)}
    end)
  end

  @spec to_defstruct(t) :: Keyword.t
  def to_defstruct(fields) do
    Enum.map(fields, fn(field) ->
      {field.name, collapse_deferred_defaults(field.default)}
    end)
  end

  @spec override_defaults(t, Keyword.t) :: t
  def override_defaults(fields, overrides) do
    Enum.reduce(overrides, fields, fn({k, v}, fields) ->
      Enum.map(fields, fn(field) ->
        maybe_set_field_default(field, k, v)
      end)
    end)
  end

  @spec override_types(t, Keyword.t) :: t
  def override_types(fields, overrides) do
    Enum.reduce(overrides, fields, fn({k, v}, fields) ->
      Enum.map(fields, fn(field) ->
        maybe_set_field_type(field, k, v)
      end)
    end)
  end

  @spec with_finalizer(t) :: t
  def with_finalizer(fields), do: fields ++ [Field.finalizer]

  defp maybe_do({:ok, x}, f) do
    {:ok, f.(x)}
  end
  defp maybe_do({:error, x}, _f), do: {:error, x}

  defp translate_type(:i8, _namespace), do: :byte
  defp translate_type({:struct, {_from_mod, struct_module}}, namespace) do
    {:struct, MacroHelpers.atom_to_elixir_module(struct_module, namespace)}
  end
  defp translate_type(%Thrift.Parser.Models.StructRef{referenced_type: struct_module}, namespace) do
    {:struct, MacroHelpers.atom_to_elixir_module(struct_module, namespace)}
  end
  defp translate_type({:map, {from_type, to_type}}, namespace) do
    {:map, {translate_type(from_type, namespace),
            translate_type(to_type, namespace)}}
  end
  defp translate_type({:set, of_type}, namespace) do
    {:set, translate_type(of_type, namespace)}
  end
  defp translate_type({:list, of_type}, namespace) do
    {:list, translate_type(of_type, namespace)}
  end
  defp translate_type(other_type, _namespace) do
    other_type
  end

  defp translate_default(%Thrift.Parser.Models.StructRef{referenced_type: struct_module},
                         _, namespace) do
    struct_module = MacroHelpers.atom_to_elixir_module(struct_module, namespace)
    {:defer_struct, struct_module}
  end
  defp translate_default(:bool, nil, _namespace), do: false
  defp translate_default({:map, {_, _}}, nil, _namespace), do: %{}
  defp translate_default({:map, {_, _}}, default_map, _namespace) do
    default_map
    |> :dict.to_list
    |> Enum.into(%{})
  end
  defp translate_default({:set, _}, nil, _namespace), do: MapSet.new
  defp translate_default({:set, _}, default_set, _namespace) do
    :sets.fold(fn(el, acc) -> MapSet.put(acc, el) end, MapSet.new, default_set)
  end
  defp translate_default({:list, _}, nil, _namespace), do: []
  defp translate_default(_, nil, _namespace), do: nil
  defp translate_default(_, default, _namespace), do: default

  defp undefined_to_nil(:undefined), do: nil
  defp undefined_to_nil(x), do: x

  defp maybe_set_field_default(field = %Field{name: field_name},
                               field_name,
                               default) do
    %{field | default: default}
  end
  defp maybe_set_field_default(field, _field_name, _default) do
    field
  end

  defp maybe_set_field_type(field = %Field{name: field_name},
                            field_name,
                            type) do
    %{field | type: type}
  end
  defp maybe_set_field_type(field, _field_name, _type) do
    field
  end

  defp collapse_deferred_defaults({:defer_struct, struct_module}) do
    if :erlang.function_exported(struct_module, :__struct__, 0) do
      struct_module.__struct__
    else
      nil
    end
  end
  defp collapse_deferred_defaults(default) do
    default
  end

  defp try_reading_struct_from(struct_name, idl) do
    case Map.get(idl.structs, struct_name) do
      nil -> {:error, []}
      struct_def -> {:ok, struct_def}
    end
  end
end
