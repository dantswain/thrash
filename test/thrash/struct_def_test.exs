defmodule Thrash.StructDefTest do
  use ExUnit.Case

  test "reading a struct def from the idl" do
    struct_def = Thrash.StructDef.find_in_thrift(:SubStruct, nil)
    assert 2 == length(struct_def)
    [f1, _] = struct_def
    assert 1 == f1.id
    assert nil == f1.default
    assert :sub_id == f1.name
    assert :i32 == f1.type
  end

  test "reading a struct def from the idl with struct fields" do
    struct_def = Thrash.StructDef.find_in_thrift(:SimpleStruct, nil)
    assert 14 == length(struct_def)
    substruct = Enum.at(struct_def, 4)
    assert :sub_struct == substruct.name
    assert {:struct, SubStruct} == substruct.type

    map = Enum.at(struct_def, 12)
    assert :map_string_to_struct == map.name
    assert {:map, {:string, {:struct, SubStruct}}} == map.type
  end

  test "expanding a struct def" do
    IO.inspect Thrash.StructDef.find_in_thrift(SimpleStruct, nil)

    struct_def = SimpleStruct
    |> Thrash.StructDef.find_in_thrift(nil)
    |> Thrash.StructDef.override_types([])
    |> Thrash.StructDef.override_defaults([])
    |> Thrash.StructDef.to_defstruct
    IO.inspect(struct_def)

    assert [] == Keyword.get(struct_def, :list_of_ints)
    assert MapSet.new == Keyword.get(struct_def, :set_of_strings)
    assert %{} == Keyword.get(struct_def, :map_string_to_struct)
  end

  test "building a struct with substructs that are namespaced" do
    IO.inspect(Thrash.StructDef.find_in_thrift(SimpleStruct, Namespaced))
    IO.inspect(Thrash.StructDef.find_in_thrift(Namespaced.SimpleStruct, nil))
    struct = %Namespaced.SimpleStruct{}
    sub_struct = %Namespaced.SubStruct{}
    assert sub_struct == struct.sub_struct

    serialized = Namespaced.SimpleStruct.serialize(struct)
    {deserialized, ""} = Namespaced.SimpleStruct.deserialize(serialized)
    assert struct == deserialized
  end

  #test "building a struct with a source works (simple case)" do
  #  # really would just fail to compile if this did not work
  #  struct = %InnerStruct{}
  #  assert struct.sub_id == nil
  #  assert struct.sub_name == nil
  #end

  #test "building a struct with a source works (nested case)" do
  #  struct = %OuterStruct{}
  #  inner_struct = %InnerStruct{}
  #  assert inner_struct == struct.sub_struct

  #  serialized = OuterStruct.serialize(struct)
  #  {deserialized, ""} = OuterStruct.deserialize(serialized)
  #  assert struct == deserialized
  #end

  #test "building a struct with a namespace and source works" do
  #  struct = %Namespaced.BStruct{}
  #  sub_struct = %Namespaced.AStruct{}
  #  assert sub_struct == struct.sub_struct

  #  serialized = Namespaced.BStruct.serialize(struct)
  #  {deserialized, ""} = Namespaced.BStruct.deserialize(serialized)
  #  assert struct == deserialized
  #end
end
