defmodule Thrash.MacroHelpers do
  @moduledoc """
  Functions that are helpful for working with macros
  """

  def determine_module_name(nil, caller) do
    get_caller_module_name(caller)
  end
  def determine_module_name({_, _, [module]}, _) do
    module
  end

  def get_caller_module_name(caller) do
    Macro.expand(quote do
                   __MODULE__
    end, caller)
  end

  def atom_to_elixir_module(atom) do
    "Elixir." <> Atom.to_string(atom)
    |> String.to_atom
  end
end

