defmodule Thrash.Protocol.Binary do
  alias Thrash.Type

  def bool_to_byte(true), do: 1
  def bool_to_byte(false), do: 0

  def byte_to_bool(1), do: true
  def byte_to_bool(0), do: false

  def deserialize_list(_, 0, {acc, str}) do
    {acc, str}
  end
  def deserialize_list(:i32, len, {acc, str}) do
    << value :: 32-signed, rest :: binary >> = str
    deserialize_list(:i32, len - 1, {[value | acc], rest})
  end
  def deserialize_list({:struct, struct_module}, len, {acc, str}) do
    {value, rest} = struct_module.deserialize(str)
    deserialize_list({:struct, struct_module}, len - 1, {[value | acc], rest})
  end

  def generate_serialize() do
    quote do
      def serialize(val) do
        serialize_field(0, val, <<>>)
      end
    end
  end

  defmacro generate(module, struct, overrides \\ []) do
    thrift_def = Thrash.read_thrift_def(module, struct, overrides)
    [generate_serialize()] ++
      generate_field_serializers(thrift_def) ++
      [generate_deserialize()] ++
      generate_field_deserializers(thrift_def)
  end

  defmacro generate(thrift_def) do
    [generate_serialize()] ++
      generate_field_serializers(thrift_def) ++
      [generate_deserialize()] ++
      generate_field_deserializers(thrift_def)
  end

  defmacro generate_serializer(thrift_def) do
    [generate_serialize()] ++ generate_field_serializers(thrift_def)
  end

  def generate_field_serializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      serializer(type, varname, ix)
    end)
  end

  def generate_deserialize() do
    quote do
      def deserialize(str, template \\ __struct__) do
        deserialize_field(str, template)
      end
    end
  end

  defmacro generate_deserializer(thrift_def) do
    [generate_deserialize()] ++ generate_field_deserializers(thrift_def)
  end

  def generate_field_deserializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      deserializer(type, varname, ix)
    end)
  end

  def deserializer(:bool, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:bool)), unquote(ix + 1) :: 16-unsigned, value :: 8-unsigned, rest :: binary >>,
                            acc) do
        value = Thrash.Protocol.Binary.byte_to_bool(value)
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:double, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:double)), unquote(ix + 1) :: 16-unsigned, value :: signed-float, rest :: binary >>,
                            acc) do
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:i32, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:i32)), unquote(ix + 1) :: 16-unsigned, value :: 32-signed, rest :: binary>>,
                            acc) do
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer({:enum, enum_module}, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:enum)), unquote(ix + 1) :: 16-unsigned, value :: 32-signed, rest :: binary >>,
                            acc) do
        value = unquote(enum_module).atom(value)
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:i64, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:i64)), unquote(ix + 1) :: 16-unsigned, value :: 64-signed, rest :: binary>>,
                            acc) do
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:string, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:string)), unquote(ix + 1) :: 16-unsigned, len :: 32-unsigned, value :: size(len)-binary, rest :: binary>>,
                            acc) do
        deserialize_field(rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer({:struct, struct_module}, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:struct)), unquote(ix + 1) :: 16-unsigned, rest :: binary >>,
                            acc) do
        {sub_struct, rest} = unquote(struct_module).deserialize(rest)
        deserialize_field(rest, Map.put(acc, unquote(fieldname), sub_struct))
      end
    end
  end
  def deserializer({:list, of_type}, fieldname, ix) do
    quote do
      def deserialize_field(<< unquote(Type.id(:list)), unquote(ix + 1) :: 16-unsigned, unquote(Type.id(of_type)), len :: 32-unsigned, rest :: binary >>,
                            acc) do
        {list, rest} = Thrash.Protocol.Binary.deserialize_list(unquote(of_type), len, {[], rest})
        deserialize_field(rest, Map.put(acc, unquote(fieldname), Enum.reverse(list)))
      end
    end
  end
  def deserializer(nil, :final, _ix) do
    quote do
      def deserialize_field(<< 0, remainder :: binary >>, acc), do: {acc, remainder}
    end
  end

  def header(type, ix) do
    quote do
      << unquote(Type.id(type)), unquote(ix) + 1 :: 16-unsigned >>
    end
  end

  def value_serializer(:bool, var) do
    quote do
      << Thrash.Protocol.Binary.bool_to_byte(unquote(Macro.var(var, __MODULE__))) :: 8-unsigned >>
    end
  end
  def value_serializer(:double, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: signed-float >>
    end
  end
  def value_serializer(:i32, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 32-signed >>
    end
  end
  def value_serializer({:enum, enum_module}, var) do
    quote do
      << unquote(enum_module).id(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned >>
    end
  end
  def value_serializer(:i64, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 64-signed >>
    end
  end
  def value_serializer(:string, var) do
    quote do
      << byte_size(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned,
      unquote(Macro.var(var, __MODULE__)) :: binary >>
    end
  end
  def value_serializer({:struct, struct_module}, var) do
    quote do
      unquote(struct_module).serialize(unquote(Macro.var(var, __MODULE__)))
    end
  end
  def value_serializer({:list, of_type}, var) do
    quote do
      << unquote(Type.id(of_type)),
      length(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned >> <>
      (Enum.map(unquote(Macro.var(var, __MODULE__)),
            fn(v) -> unquote(value_serializer(of_type, :v)) end)
       |> Enum.join)
    end
  end

  def empty_value?({:struct, struct_module}) do
    quote do
      value == nil || value == unquote(struct_module).__struct__
    end
  end
  def empty_value?({:list, _}) do
    quote do
      value == nil || value == []
    end
  end
  def empty_value?(_) do
    quote do
      value == nil
    end
  end

  def splice_binaries({:<<>>, _, p1}, {:<<>>, _, p2}) do
    {:<<>>, [], p1 ++ p2}
  end
  def splice_binaries(b1, b2) do
    quote do: unquote(b1) <> unquote(b2)
  end

  def serializer(nil, :final, ix) do
    quote do
      def serialize_field(unquote(ix), _, acc), do: acc <> << 0 >>
    end
  end
  def serializer(type, fieldname, ix) do
    quote do
      def serialize_field(unquote(ix), val, acc) do
        value = Map.get(val, unquote(fieldname))
        if unquote(empty_value?(type)) do
          serialize_field(unquote(ix) + 1, val, acc)
        else
          serialize_field(unquote(ix) + 1,
                          val,
                          acc <> unquote(splice_binaries(header(type, ix),
                                                         value_serializer(type, :value))))
        end
      end
    end
  end
end
