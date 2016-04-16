defmodule Thrash.MacroHelpers do
  @moduledoc false

  # Functions that are helpful for working with macros
  # Thrash internal use only

  @type escaped_module_name :: {term, list, [atom]}
  @type namespace :: nil | {atom, atom}

  @doc """
  Determine the caller module name with optional override.

  Use with the `__CALLER__.module` value as the second argument.
  """
  @spec determine_module_name(nil | escaped_module_name, atom) :: atom
  def determine_module_name(nil, caller) do
    caller
  end
  def determine_module_name({:__aliases__, _, [module]}, _) do
    module
  end

  @doc """
  Turn an atom into an elixir module name with optional namespace.

  Examples:
      iex> Thrash.MacroHelpers.atom_to_elixir_module(:Struct, nil)
      Struct

      iex> Thrash.MacroHelpers.atom_to_elixir_module(Struct, nil)
      Struct

      iex> Thrash.MacroHelpers.atom_to_elixir_module(:Struct, Namespace)
      Namespace.Struct

      iex> Thrash.MacroHelpers.atom_to_elixir_module(:Struct, :Namespace)
      Namespace.Struct
  """
  @spec atom_to_elixir_module(atom, nil | atom) :: atom
  def atom_to_elixir_module(atom, nil) do
    atom
    |> Atom.to_string
    |> moduleize
    |> String.to_atom
  end
  def atom_to_elixir_module(atom, namespace) do
    atom
    |> Atom.to_string
    |> prepend_string_namespace(namespace)
    |> moduleize
    |> String.to_atom
  end

  @doc """
  Determine the namespace of a module name

  Examples:
      iex> Thrash.MacroHelpers.find_namespace(Foo)
      nil

      iex> Thrash.MacroHelpers.find_namespace(Foo.Bar)
      Foo

      iex> Thrash.MacroHelpers.find_namespace(Foo.Bar.Baz)
      Foo.Bar
  """
  @spec find_namespace(atom) :: namespace
  def find_namespace(modulename) do
    parts = modulename
    |> Atom.to_string
    |> String.reverse
    |> String.split(".", parts: 2)
    |> Enum.map(&String.reverse/1)
    |> Enum.map(&moduleize/1)
    |> Enum.reject(fn(e) -> e == nil end)
    |> Enum.map(&String.to_atom/1)

    case parts do
      [_modulename] -> nil
      [_modulename, namespace] -> namespace
    end
  end

  @doc """
  Create a quoted 'or' expression for an array of values.

  Useful for generating typespecs, i.e., `:foo | :bar | :baz`

  Examples:
      iex> Thrash.MacroHelpers.quoted_chained_or([:a, :b])
      quote do: :a | :b

      iex> Thrash.MacroHelpers.quoted_chained_or([:a, :b, :c])
      quote do: :a | :b | :c
  """
  def quoted_chained_or(values) when is_list(values) and length(values) > 1 do
    values = Enum.reverse(values)
    [a, b | rest] = values
    quoted_chained_or(rest, {:|, [], [b, a]})
  end

  defp moduleize("Elixir") do
    nil
  end
  defp moduleize(modulename = "Elixir." <> _string) do
    modulename
  end
  defp moduleize(string) do
    "Elixir." <> string
  end

  defp prepend_string_namespace(module_name, namespace) do
    (Atom.to_string(namespace) <> "." <> module_name)
  end

  defp quoted_chained_or([], ast) do
    ast
  end
  defp quoted_chained_or([h | rest], ast) do
    quoted_chained_or(rest, {:|, [], [h, ast]})
  end
end
