defmodule Thrash do
  def read_thrift_def(mod, struct_name, overrides \\ []) do
    {:struct, fields} = mod.struct_info_ext(struct_name)
    fields
    |> Enum.map(fn({_id, _, type, name, _}) ->
      {name, translate_type(type, name, overrides)}
    end)
  end

  def read_struct_def(mod, struct_name, overrides \\ [], defaults \\ []) do
    read_thrift_def(mod, struct_name, overrides)
    |> Enum.map(fn({k, v}) ->
      {k, Keyword.get(defaults, k, default_for_type(v))}
    end)
  end

  def read_enum(header_file, namespace) do
    Quaff.Constants.get_constants(header_file, [])
    |> Enum.filter_map(
      fn({k, _v}) -> Atom.to_string(k) |> String.starts_with?(namespace) end,
      fn({k, v}) ->
        {Atom.to_string(k)
         |> String.replace(~r/^#{namespace}_/, "")
         |> String.downcase
         |> String.to_atom, v}
        end)
    |> Enum.into(%{})
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
  defp default_for_type(_), do: nil
end
