defmodule Thrash.BinaryTest do
  use ExUnit.Case

  defmodule TestStruct do
    defstruct id: nil, name: nil, list_of_ints: []

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_deserializer(id: :i32, name: :string, list_of_ints: {:list, :i32})
    Thrash.Protocol.Binary.generate_serializer(id: :i32, name: :string, list_of_ints: {:list, :i32})
  end

  test "deserializes a struct" do
    str = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x0F\x00\x03\b\x00\x00\x00\x06\x00\x00\x00\x04\x00\x00\x00\b\x00\x00\x00\x0F\x00\x00\x00\x10\x00\x00\x00\x17\x00\x00\x00*\x00"
    expected = %TestStruct{id: 42, name: "my thing", list_of_ints: [4, 8, 15, 16, 23, 42]}
    deserialized = TestStruct.deserialize(str)
    assert(deserialized == expected)
  end

  test "serializes a struct" do
    struct = %TestStruct{id: 42, name: "my thing", list_of_ints: [4, 8, 15, 16, 23, 42]}
    expected = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x0F\x00\x03\b\x00\x00\x00\x06\x00\x00\x00\x04\x00\x00\x00\b\x00\x00\x00\x0F\x00\x00\x00\x10\x00\x00\x00\x17\x00\x00\x00*\x00"
    serialized = TestStruct.serialize(struct)
    assert(serialized == expected)
  end
end
