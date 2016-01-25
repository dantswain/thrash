defmodule Thrash.BinaryAcceleratedTest do
  use ExUnit.Case

  defmodule SimpleStruct do
    defstruct id: nil, name: nil

    require Thrash.Protocol.BinaryAccelerated
    Thrash.Protocol.BinaryAccelerated.generate_deserializer(id: :i32, name: :string)
    Thrash.Protocol.BinaryAccelerated.generate_serializer(id: :i32, name: :string)
  end

  test "deserializes a struct" do
    str = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    expected = %SimpleStruct{id: 42, name: "my thing"}
    deserialized = SimpleStruct.deserialize(str)
    assert(deserialized == expected)
  end

  test "serializes a struct" do
    struct = %SimpleStruct{id: 42, name: "my thing"}
    expected = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    serialized = SimpleStruct.serialize(struct)
    assert(serialized == expected)
  end
end
