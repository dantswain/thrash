defmodule ThrashTest do
  use ExUnit.Case
  doctest Thrash

  defmodule SimpleStruct do
    defstruct id: nil, name: nil

    require Thrash.BinaryAcceleratedProtocol
    Thrash.BinaryAcceleratedProtocol.generate_deserializer(id: :i32, name: :string)
    Thrash.BinaryAcceleratedProtocol.generate_serializer(id: :i32, name: :string)
  end

  test "deserializes a struct" do
    str = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    expected = %ThrashTest.SimpleStruct{id: 42, name: "my thing"}
    deserialized = ThrashTest.SimpleStruct.deserialize(str)
    assert(deserialized == expected)
  end

  test "serializes a struct" do
    struct = %ThrashTest.SimpleStruct{id: 42, name: "my thing"}
    expected = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    serialized = ThrashTest.SimpleStruct.serialize(struct)
    assert(serialized == expected)
  end
end
