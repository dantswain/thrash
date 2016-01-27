defmodule Bench do
  defmodule TestSubStruct do
    defstruct sub_id: nil, sub_name: nil

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_deserializer(sub_id: :i32, sub_name: :string)
    Thrash.Protocol.Binary.generate_serializer(sub_id: :i32, sub_name: :string)
  end

  defmodule TestStruct do
    defstruct id: nil, name: nil, list_of_ints: [], bigint: nil, sub_struct: %TestSubStruct{}

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_deserializer(id: :i32,
                                                 name: :string,
                                                 list_of_ints: {:list, :i32},
                                                 bigint: :i64,
                                                 sub_struct: {:struct, TestSubStruct})
    Thrash.Protocol.Binary.generate_serializer(id: :i32,
                                               name: :string,
                                               list_of_ints: {:list, :i32},
                                               bigint: :i64,
                                               sub_struct: {:struct, TestSubStruct})
  end

  def bench_thrift_ex() do
    require SubStruct
    require SimpleStruct

    sub = SubStruct.sub_struct(sub_id: 77, sub_name: "sub thing")
    s = SimpleStruct.simple_struct(id: 42,
                                   name: "my thing",
                                   list_of_ints: [4, 8, 15, 16, 23, 42],
                                   bigint: -9999999999999,
                                   sub_struct: sub)
    str = ThriftEx.to_binary(s, SimpleStruct.struct_info)

    Benchwarmer.benchmark(fn ->
      ThriftEx.to_binary(s, SimpleStruct.struct_info)
    end)

    Benchwarmer.benchmark(fn ->
      ThriftEx.from_binary(str, SimpleStruct.struct_info, :SimpleStruct)
    end)
  end

  def bench_thrash() do
    sub = %TestSubStruct{sub_id: 77, sub_name: "a sub struct"}
    s = %TestStruct{id: 42,
                    name: "my thing",
                    list_of_ints: [4, 8, 15, 16, 23, 42],
                    bigint: -9999999999999,
                    sub_struct: sub}

    str = TestStruct.serialize(s)

    Benchwarmer.benchmark(fn ->
      TestStruct.serialize(s)
    end)

    Benchwarmer.benchmark(fn ->
      TestStruct.deserialize(str)
    end)
  end
end
