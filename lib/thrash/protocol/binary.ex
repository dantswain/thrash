defmodule Thrash.Protocol.Binary do
  alias Thrash.Type

  def deserialize_list(_, 0, {acc, str}) do
    {acc, str}
  end
  def deserialize_list(:i32, len, {acc, str}) do
    << value :: 32-signed, rest :: binary >> = str
    deserialize_list(:i32, len - 1, {[value | acc], rest})
  end

  def serialize_list(:i32, list) do
    (for el <- list, do: << el :: 32-signed >>) |> Enum.join
  end

  defmacro generate_serializer(thrift_def) do
    [quote do
       def serialize(val) do
         serialize_field(0, val, <<>>)
       end
    end] ++ generate_field_serializers(thrift_def)
  end

  def generate_field_serializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      serializer(type, varname, ix)
    end)
  end

  defmacro generate_deserializer(thrift_def) do
    [quote do
       def deserialize(str, template \\ __struct__) do
         deserialize_field(0, str, template)
       end
    end] ++ generate_field_deserializers(thrift_def)
  end

  def generate_field_deserializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      deserializer(type, varname, ix)
    end)
  end

  def deserializer(:i32, fieldname, ix) do
    quote do
      def deserialize_field(unquote(ix),
                            <<unquote(Type.id(:i32)), unquote(ix + 1) :: 16-unsigned, value :: 32-signed, rest :: binary>>,
                            acc) do
        deserialize_field(unquote(ix) + 1, rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:i64, fieldname, ix) do
    quote do
      def deserialize_field(unquote(ix),
                            <<unquote(Type.id(:i64)), unquote(ix + 1) :: 16-unsigned, value :: 64-signed, rest :: binary>>,
                            acc) do
        deserialize_field(unquote(ix) + 1, rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer(:string, fieldname, ix) do
    quote do
      def deserialize_field(unquote(ix),
                            << unquote(Type.id(:string)), unquote(ix + 1) :: 16-unsigned, len :: 32-unsigned, value :: size(len)-binary, rest :: binary>>,
                            acc) do
        deserialize_field(unquote(ix) + 1, rest, Map.put(acc, unquote(fieldname), value))
      end
    end
  end
  def deserializer({:list, of_type}, fieldname, ix) do
    quote do
      def deserialize_field(unquote(ix),
                            << unquote(Type.id(:list)), unquote(ix + 1) :: 16-unsigned, unquote(Type.id(of_type)), len :: 32-unsigned, rest :: binary >>,
                            acc) do
        {list, rest} = Thrash.Protocol.Binary.deserialize_list(unquote(of_type), len, {[], rest})
        deserialize_field(unquote(ix) + 1, rest, Map.put(acc, unquote(fieldname), Enum.reverse(list)))
      end
    end
  end
  def deserializer(nil, :final, ix) do
    quote do
      def deserialize_field(unquote(ix), _, acc), do: acc
    end
  end

  def serializer(:i32, fieldname, ix) do
    quote do
      def serialize_field(unquote(ix), val, acc) do
        serialize_field(unquote(ix) + 1, val,
                        acc <> << unquote(Type.id(:i32)), unquote(ix) + 1 :: 16-unsigned, (Map.get(val, unquote(fieldname))) :: 32-signed >>)
      end
    end
  end
  def serializer(:i64, fieldname, ix) do
    quote do
      def serialize_field(unquote(ix), val, acc) do
        serialize_field(unquote(ix) + 1, val,
                        acc <> << unquote(Type.id(:i64)), unquote(ix) + 1 :: 16-unsigned, (Map.get(val, unquote(fieldname))) :: 64-signed >>)
      end
    end
  end
  def serializer(:string, fieldname, ix) do
    quote do
      def serialize_field(unquote(ix), val, acc) do
        str = Map.get(val, unquote(fieldname))
        serialize_field(unquote(ix) + 1, val,
                        acc <> << unquote(Type.id(:string)), unquote(ix) + 1 :: 16-unsigned, byte_size(str) :: 32-unsigned, str :: binary >>)
      end
    end
  end
  def serializer({:list, of_type}, fieldname, ix) do
    quote do
      def serialize_field(unquote(ix), val, acc) do
        list = Map.get(val, unquote(fieldname))
        header = << unquote(Type.id(:list)), unquote(ix) + 1 :: 16-unsigned, unquote(Type.id(of_type)), length(list) :: 32-unsigned >>
        serialized = Thrash.Protocol.Binary.serialize_list(unquote(of_type), list)
        serialize_field(unquote(ix) + 1, val, acc <> header <> serialized)
      end
    end
  end
  def serializer(nil, :final, ix) do
    quote do
      def serialize_field(unquote(ix), _, acc), do: acc <> << 0 >>
    end
  end
end
