defmodule Bench do
  defmodule TacoType do
    @mapping %{
      carnitas: 124
    }

    @reverse_mapping Enum.into(@mapping, []) |> Enum.map(fn({k, v}) -> {v, k} end) |> Enum.into(%{})

    def id(sym), do: @mapping[sym]

    def atom(id), do: @reverse_mapping[id]
  end

  defmodule TestSubStruct do
    defstruct sub_id: nil, sub_name: nil

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_deserializer(sub_id: :i32, sub_name: :string)
    Thrash.Protocol.Binary.generate_serializer(sub_id: :i32, sub_name: :string)
  end

  defmodule TestStruct do
    defstruct(id: nil,
              name: nil,
              list_of_ints: [],
              bigint: nil,
              sub_struct: %TestSubStruct{},
              flag: false,
              floatval: nil,
              taco_pref: :chicken,
              list_of_structs: [])

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_deserializer(id: :i32,
                                                 name: :string,
                                                 list_of_ints: {:list, :i32},
                                                 bigint: :i64,
                                                 sub_struct: {:struct, TestSubStruct},
                                                 flag: :bool,
                                                 floatval: :double,
                                                 taco_pref: {:enum, TacoType},
                                                 list_of_structs: {:list, TestSubStruct})
    Thrash.Protocol.Binary.generate_serializer(id: :i32,
                                               name: :string,
                                               list_of_ints: {:list, :i32},
                                               bigint: :i64,
                                               sub_struct: {:struct, TestSubStruct},
                                               flag: :bool,
                                               floatval: :double,
                                               taco_pref: {:enum, TacoType},
                                               list_of_structs: {:list, TestSubStruct})
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
    s = %TestStruct{id: 42,
                    name: "my thing",
                    list_of_ints: [4, 8, 15, 16, 23, 42],
                    bigint: -9999999999999,
                    sub_struct: sub_struct,
                    flag: true,
                    floatval: 3.14159265,
                    taco_pref: :carnitas,
                    list_of_structs: list_of_sub_structs}

    str = TestStruct.serialize(s)

    IO.puts("Benchmarking Thrash serialization")
    Benchwarmer.benchmark(fn ->
      TestStruct.serialize(s)
    end)

    IO.puts("Benchmarking Thrash deserialization")
    Benchwarmer.benchmark(fn ->
      TestStruct.deserialize(str)
    end)

    IO.puts("Done")
  end
end
