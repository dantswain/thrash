defmodule Thrash.StructDef do
  @moduledoc """
  Thrash's translation layer between the Thrift IDL and the generated
  Elixir code.
  """

  defmodule Field do
    defstruct(id: nil, required: nil, type: nil, name: nil, default: nil)

    def finalizer do
      %Field{name: :final}
    end
  end

  alias Thrash.ThriftMeta

  def find_in_thrift(modulename, namespace) do
    ThriftMeta.find_in_thrift(fn(h) ->
      ThriftMeta.read_struct(h, modulename, namespace)
    end, :struct_not_found)
  end

  def read(modulename, struct_name, namespace) do
    try do
      {:ok, modulename.struct_info_ext(struct_name)}
    rescue
      _e in FunctionClauseError ->
        {:error, []}
    end
    |> maybe_do(fn(struct_info) -> from_struct_info(namespace, struct_info) end)
  end

  def from_struct_info(namespace, {:struct, fields}) do
    Enum.map(fields, fn({id, required, type, name, default}) ->
      %Field{id: id,
             required: undefined_to_nil(required),
             type: translate_type(type, namespace),
             name: name,
             default: translate_default(type, default, namespace)}
    end)
  end

  def to_defstruct(fields) do
    Enum.map(fields, fn(field) ->
      {field.name, collapse_deferred_defaults(field.default)}
    end)
  end

  def override_defaults(fields, overrides) do
    Enum.reduce(overrides, fields, fn({k, v}, fields) ->
      Enum.map(fields, fn(field) ->
        maybe_set_field_default(field, k, v)
      end)
    end)
  end

  def override_types(fields, overrides) do
    Enum.reduce(overrides, fields, fn({k, v}, fields) ->
      Enum.map(fields, fn(field) ->
        maybe_set_field_type(field, k, v)
      end)
    end)
  end

  defp maybe_do({:ok, x}, f) do
    {:ok, f.(x)}
  end
  defp maybe_do({:error, x}, _f), do: {:error, x}

  defp translate_type({:struct, {_from_mod, struct_module}}, namespace) do
    {:struct, Thrash.MacroHelpers.atom_to_elixir_module(struct_module, namespace)}
  end
  defp translate_type({:list, of_type}, namespace) do
    {:list, translate_type(of_type, namespace)}
  end
  defp translate_type(other_type, _namespace), do: other_type

  defp translate_default({:struct, {_thrift_namespace, struct_module}}, _, namespace) do
    struct_module = Thrash.MacroHelpers.atom_to_elixir_module(struct_module, namespace)
    {:defer_struct, struct_module}
  end
  defp translate_default(:bool, :undefined, _namespace), do: false
  defp translate_default({:list, _}, :undefined, _namespace), do: []
  defp translate_default(_, :undefined, _namespace), do: nil
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
    struct_module.__struct__
  end
  defp collapse_deferred_defaults(default) do
    default
  end
end
