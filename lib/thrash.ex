defmodule Thrash do
  def read_thrift_def(mod, struct_name, overrides \\ []) do
    {:struct, fields} = mod.struct_info_ext(struct_name)
    fields
    |> Enum.map(fn({_id, _, type, name, _}) ->
      {name, translate_type(type, name, overrides)}
    end)
  end

  def read_struct_def(mod, struct_name, defaults \\ []) do
    read_thrift_def(mod, struct_name)
    |> Enum.map(fn({k, v}) ->
      {k, Keyword.get(defaults, k, default_for_type(v))}
    end)
  end

  defp translate_type(type, name, overrides) do
    if Keyword.has_key?(overrides, name) do
      Keyword.get(overrides, name)
    else
      translate_type(type)
    end
  end

  defp translate_type({:struct, {_from_mod, struct_module}}) do
    {:struct, to_elixir_module(struct_module)}
  end
  defp translate_type({:list, of_type}) do
    {:list, translate_type(of_type)}
  end
  defp translate_type(other_type), do: other_type

  defp to_elixir_module(atom) do
    "Elixir." <> Atom.to_string(atom)
    |> String.to_atom
  end

  defp default_for_type({:struct, struct_module}) do
    struct_module.__struct__
  end
  defp default_for_type(:bool), do: false
  defp default_for_type({:list, _}), do: []
  defp default_for_type(x), do: nil
end
