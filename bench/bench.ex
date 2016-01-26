defmodule Bench do
  defmodule ThrashSimpleStruct do
    defstruct id: nil, name: nil

    require Thrash.Protocol.Binary
    Thrash.Protocol.Binary.generate_serializer(id: :i32, name: :string)
    Thrash.Protocol.Binary.generate_deserializer(id: :i32, name: :string)
  end

  def bench_thrift_ex() do
    require SimpleStruct

    s = SimpleStruct.simple_struct(id: 42, name: "my thing")
    str = ThriftEx.to_binary(s, SimpleStruct.struct_info)

    Benchwarmer.benchmark(fn ->
      ThriftEx.to_binary(s, SimpleStruct.struct_info)
    end)

    Benchwarmer.benchmark(fn ->
      ThriftEx.from_binary(str, SimpleStruct.struct_info, :SimpleStruct)
    end)
  end

  def bench_thrash() do
    s = %ThrashSimpleStruct{id: 42, name: "my thing"}
    str = ThrashSimpleStruct.serialize(s)

    Benchwarmer.benchmark(fn ->
      ThrashSimpleStruct.serialize(s)
    end)

    Benchwarmer.benchmark(fn ->
      ThrashSimpleStruct.deserialize(str)
    end)
  end
end
