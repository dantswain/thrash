defmodule Thrash.StructDefTest do
  use ExUnit.Case

  test "building a struct with substructs that are namespaced" do
    struct = %Namespaced.SimpleStruct{}
    sub_struct = %Namespaced.SubStruct{}
    assert sub_struct == struct.sub_struct
  end
end
