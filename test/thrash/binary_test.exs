defmodule Thrash.BinaryTest do
  use ExUnit.Case, async: false

  def dump_bin(name, b) do
    IO.puts("#{name}:")
    b
    |> :binary.bin_to_list
    |> Enum.chunk(50, 50, [])
    |> Enum.each(fn(c) -> IO.puts(inspect c) end)
  end

  def test_str do
    hex = "0800010000002A0B0002000000086D79207468696E670F0003080000000600000004000000080000000F00000010000000170000002A0A0004FFFFF6E7B18D60010C00050800010000004D0B00020000000C6120737562207374727563740002000601040007400921FB53C8D4F10800080000007C0F00090C00000005080001000000010B00020000000B737562207468696E67203100080001000000020B00020000000B737562207468696E67203200080001000000030B00020000000B737562207468696E67203300080001000000040B00020000000B737562207468696E67203400080001000000050B00020000000B737562207468696E6720350003000A0306000B80000D000C080B00000002000000000000000C655E7B692A70697D202B20310000002A000000036C75650D000D0B0C00000002000000036F6E65080001000000010B00020000000A6D6170706564206F6E65000000000374776F080001000000020B00020000000A6D61707065642074776F0000"
    Base.decode16!(hex)
  end

  def test_struct do
    sub_struct = %SubStruct{sub_id: 77, sub_name: "a sub struct"}
    list_of_sub_structs = (1..5) |> Enum.map(fn(ix) ->
      %SubStruct{sub_id: ix, sub_name: "sub thing #{ix}"}
    end)
    %SimpleStruct{id: 42,
                  name: "my thing",
                  list_of_ints: [4, 8, 15, 16, 23, 42],
                  bigint: -9999999999999,
                  sub_struct: sub_struct,
                  flag: true,
                  floatval: 3.14159265,
                  taco_pref: :carnitas,
                  list_of_structs: list_of_sub_structs,
                  chew: 3,
                  mediumint: -32768,
                  map_int_to_string: %{ 42 => "lue",
                                        0 => "e^{i*pi} + 1"},
                  map_string_to_struct: %{
                    "one" => %SubStruct{sub_id: 1,
                                        sub_name: "mapped one"},
                    "two" => %SubStruct{sub_id: 2,
                                        sub_name: "mapped two"}
                  }}
  end

  def optionals_str do
    hex = "0800010000002A0F0003080000000600000004000000080000000F00000010000000170000002A0A0004FFFFF6E7B18D600102000601040007400921FB53C8D4F10800080000007C00"
    Base.decode16!(hex)
  end

  def optionals_struct do
    %SimpleStruct{id: 42,
                  list_of_ints: [4, 8, 15, 16, 23, 42],
                  bigint: -9999999999999,
                  flag: true,
                  floatval: 3.14159265,
                  taco_pref: :carnitas}
  end

  test "defined struct has the correct defaults" do
    struct = %SimpleStruct{}
    assert :chicken == struct.taco_pref
  end

  test "deserializes a struct" do
    {deserialized, ""} = SimpleStruct.deserialize(test_str)
    assert(deserialized == test_struct)
  end

  test "serializes a struct" do
    serialized = SimpleStruct.serialize(test_struct)
    assert(serialized == test_str)
  end

  test "deserializes a struct with optional fields absent" do
    {deserialized, ""} = SimpleStruct.deserialize(optionals_str)
    assert(deserialized == optionals_struct)
  end

  test "serializes a struct with optional fields absent" do
    serialized = SimpleStruct.serialize(optionals_struct)
    assert(serialized == optionals_str)
  end
end
