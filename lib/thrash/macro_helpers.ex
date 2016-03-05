defmodule Thrash.MacroHelpers do
  @moduledoc """
  Functions that are helpful for working with macros
  """

  @type escaped_module_name :: {term, list, [atom]}

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
    moduleize(Atom.to_string(atom))
    |> String.to_atom
  end
  def atom_to_elixir_module(atom, namespace) do
    (Atom.to_string(namespace) <> "." <> Atom.to_string(atom))
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
  @spec find_namespace(atom) :: {nil | atom, atom}
  def find_namespace(modulename) do
    parts = Atom.to_string(modulename)
    |> String.reverse
    |> String.split(".", parts: 2)
    |> Enum.map(&String.reverse/1)
    |> Enum.map(&moduleize/1)
    |> Enum.reject(fn(e) -> e == nil end)
    |> Enum.map(&String.to_atom/1)

    case parts do
      [modulename] -> nil
      [modulename, namespace] -> namespace
    end
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
end
