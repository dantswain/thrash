defmodule Thrash.EnumeratedTest do
  use ExUnit.Case

  # note TacoType comes from test/simple_struct.ex, which is generated
  # from the thrift hrl

  test "Creates a lookup from atom to id" do
    assert TacoType.id(:barbacoa) == 123
  end

  test "Creates a lookup from id to atom" do
    assert TacoType.atom(125) == :steak
  end

  test "source module name works" do
    assert TacoFlavor.id(:barbacoa) == 123
  end

  test "creates an atoms list" do
    assert Map.keys(TacoType.map) == TacoType.atoms
  end

  test "creats a values list" do
    assert Map.values(TacoType.map) == TacoType.values
  end

  test "defines a type for atoms" do
    type = {:atom_t,
            {:type, 2, :union,
              Enum.map(TacoType.atoms, fn(t) -> {:atom, 0, t} end)},
            []}
    types = Kernel.Typespec.beam_types(TacoType)
    assert Enum.member?(types, {:type, type})
  end

  test "defines a type for values" do
    type = {:values_t,
            {:type, 2, :union,
              Enum.map(TacoType.values, fn(t) -> {:integer, 0, t} end)},
            []}
    types = Kernel.Typespec.beam_types(TacoType)
    assert Enum.member?(types, {:type, type})
  end
end
