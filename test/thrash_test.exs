defmodule ThrashTest do
  use ExUnit.Case
  doctest Thrash

  defmodule SimpleStruct do
    defstruct id: nil, name: nil

    def deserialize(str, :binary_accelerated_protocol) do
      <<8, 0, 1, id :: 32-signed, 11, 0, 2, name_size :: 32-unsigned, name :: size(name_size)-binary, 0>> = str

      %SimpleStruct{id: id, name: name}
    end

    def serialize(struct, :binary_accelerated_protocol) do
      <<8, 0, 1, struct.id :: 32-signed, 11, 0, 2, byte_size(struct.name) :: 32-unsigned, struct.name :: binary, 0>>
    end
  end

  test "deserializes a struct" do
    str = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    expected = %ThrashTest.SimpleStruct{id: 42, name: "my thing"}
    deserialized = ThrashTest.SimpleStruct.deserialize(str, :binary_accelerated_protocol)
    assert(deserialized == expected)
  end

  test "serializes a struct" do
    struct = %ThrashTest.SimpleStruct{id: 42, name: "my thing"}
    expected = "\b\x00\x01\x00\x00\x00*\v\x00\x02\x00\x00\x00\bmy thing\x00"
    serialized = ThrashTest.SimpleStruct.serialize(struct, :binary_accelerated_protocol)
    assert(serialized == expected)
  end
end
