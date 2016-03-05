defmodule Thrash.StructDefTest do
  use ExUnit.Case

  test "building a struct with substructs that are namespaced" do
    struct = %Namespaced.SimpleStruct{}
    sub_struct = %Namespaced.SubStruct{}
    assert sub_struct == struct.sub_struct

    serialized = Namespaced.SimpleStruct.serialize(struct)
    {deserialized, ""} = Namespaced.SimpleStruct.deserialize(serialized)
    assert struct == deserialized
  end

  test "building a struct with a source works (simple case)" do
    # really would just fail to compile if this did not work
    struct = %InnerStruct{}
    assert struct.sub_id == nil
    assert struct.sub_name == nil
  end

  test "building a struct with a source works (nested case)" do
    struct = %OuterStruct{}
    inner_struct = %InnerStruct{}
    assert inner_struct == struct.sub_struct

    serialized = OuterStruct.serialize(struct)
    {deserialized, ""} = OuterStruct.deserialize(serialized)
    assert struct == deserialized
  end

  test "building a struct with a namespace and source works" do
    struct = %Namespaced.BStruct{}
    sub_struct = %Namespaced.AStruct{}
    assert sub_struct == struct.sub_struct

    serialized = Namespaced.BStruct.serialize(struct)
    {deserialized, ""} = Namespaced.BStruct.deserialize(serialized)
    assert struct == deserialized
  end
end
