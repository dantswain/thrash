defmodule Bench do
  defmodule TacoType do
    use Thrash.Enumerated, {"src/gen-erl/thrash_test_types.hrl",
                            "THRASH_TEST_TACOTYPE"}
  end

  defmodule TestSubStruct do
    defstruct(Thrash.read_struct_def(:thrash_test_types, :'SubStruct'))

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate(:thrash_test_types, :'SubStruct')
  end

  defmodule TestSimpleStruct do
    defstruct(Thrash.read_struct_def(:thrash_test_types,
                                     :'SimpleStruct',
                                     [taco_pref: {:enum, TacoType},
                                      sub_struct: {:struct, TestSubStruct},
                                      list_of_structs: {:list, {:struct, TestSubStruct}}],
                                     [taco_pref: :chicken,
                                      sub_struct: %TestSubStruct{}]))

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate(:thrash_test_types,
                                    :'SimpleStruct',
                                    taco_pref: {:enum, TacoType},
                                    sub_struct: {:struct, TestSubStruct},
                                    list_of_structs: {:list, {:struct, TestSubStruct}})
  end

  def bench_thrift_ex() do
    require SubStruct
    require SimpleStruct

    sub = SubStruct.sub_struct(sub_id: 77, sub_name: "sub thing")
    list_of_sub_structs = (1..5) |> Enum.map(fn(ix) ->
      SubStruct.sub_struct(sub_id: ix, sub_name: "#sub thing #{ix}")
    end)
    s = SimpleStruct.simple_struct(id: 42,
                                   name: "my thing",
                                   list_of_ints: [4, 8, 15, 16, 23, 42],
                                   bigint: -9999999999999,
                                   sub_struct: sub,
                                   flag: true,
                                   floatval: 3.14159265,
                                   taco_pref: ThrashTestConstants.thrash_test_tacotype_carnitas,
                                   list_of_structs: list_of_sub_structs)
    str = ThriftEx.to_binary(s, SimpleStruct.struct_info)

    IO.puts("Benchmarking Thrift serialization")
    Benchwarmer.benchmark(fn ->
      ThriftEx.to_binary(s, SimpleStruct.struct_info)
    end)

    IO.puts("Benchmarking Thrift deserialization")
    Benchwarmer.benchmark(fn ->
      ThriftEx.from_binary(str, SimpleStruct.struct_info, :SimpleStruct)
    end)

    IO.puts("Done")
  end

  def bench_thrash() do
    sub_struct = %TestSubStruct{sub_id: 77, sub_name: "a sub struct"}
    list_of_sub_structs = (1..5) |> Enum.map(fn(ix) ->
      %TestSubStruct{sub_id: ix, sub_name: "sub thing #{ix}"}
    end)
    s = %TestSimpleStruct{id: 42,
                          name: "my thing",
                          list_of_ints: [4, 8, 15, 16, 23, 42],
                          bigint: -9999999999999,
                          sub_struct: sub_struct,
                          flag: true,
                          floatval: 3.14159265,
                          taco_pref: :carnitas,
                          list_of_structs: list_of_sub_structs}

    str = TestSimpleStruct.serialize(s)

    IO.puts("Benchmarking Thrash serialization")
    Benchwarmer.benchmark(fn ->
      TestSimpleStruct.serialize(s)
    end)

    IO.puts("Benchmarking Thrash deserialization")
    Benchwarmer.benchmark(fn ->
      TestSimpleStruct.deserialize(str)
    end)

    IO.puts("Done")
  end
end
