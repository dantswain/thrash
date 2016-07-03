defmodule Thrash.BinaryPropertiesTest do
  use ExUnit.Case, async: false
  use ExCheck

  property :int32 do
    for_all x in int do
      sub_struct = %SubStruct{sub_id: x}
      {got_sub_struct, ""} = SubStruct.deserialize(SubStruct.serialize(sub_struct))
      sub_struct == got_sub_struct
    end
  end
end
