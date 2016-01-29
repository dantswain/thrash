defmodule ThrashTest do
  use ExUnit.Case
  doctest Thrash

  test "reading thrift info from the thrift-generated erlang files" do
    expected = [
      id: :i32,
      name: :string,
      list_of_ints: {:list, :i32},
      bigint: :i64,
      sub_struct: {:struct, SubStruct},
      flag: :bool,
      floatval: :double,
      taco_pref: {:enum, TacoType},
      list_of_structs: {:list, {:struct, SubStruct}}
    ]

    assert expected == Thrash.read_thrift_def(:thrash_test_types,
                                              :'SimpleStruct',
                                              taco_pref: {:enum, TacoType})
  end

  test "reading a struct def from the thrift-generated erlang files" do
    expected = [id: nil,
                name: nil,
                list_of_ints: [],
                bigint: nil,
                sub_struct: %SubStruct{},
                flag: false,
                floatval: nil,
                taco_pref: :chicken,
                list_of_structs: []]

    assert expected == Thrash.read_struct_def(:thrash_test_types,
                                              :'SimpleStruct',
                                              taco_pref: :chicken)
  end

  test "reading an enum from a thrift-generated hrl file" do
    expected = %{
      barbacoa: 123,
      carnitas: 124,
      steak: 125,
      chicken: 126,
      pastor: 127}

    assert expected == Thrash.read_enum("src/gen-erl/thrash_test_types.hrl",
                                        "THRASH_TEST_TACOTYPE")
  end
end
