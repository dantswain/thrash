defmodule Bench do
  defmodule TacoType do
    use Thrash.Enumerated
  end

  defmodule TestSubStruct do
    use Thrash.Protocol.Binary, source: SubStruct
  end

  defmodule TestSimpleStruct do
    use Thrash.Protocol.Binary, source: SimpleStruct,
                                defaults: [taco_pref: :chicken,
                                           sub_struct: %Bench.TestSubStruct{}],
                                types: [taco_pref: {:enum, TacoType},
                                        sub_struct: {:struct, %Bench.TestSubStruct{}}]
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
