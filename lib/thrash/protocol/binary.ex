defmodule Thrash.Protocol.Binary do
  alias Thrash.Type

  defmacro generate(module, struct, overrides \\ []) do
    thrift_def = Thrash.read_thrift_def(module, struct, overrides)
    [generate_serialize()] ++
      generate_field_serializers(thrift_def) ++
      [generate_deserialize()] ++
      generate_field_deserializers(thrift_def)
  end

  def bool_to_byte(true), do: 1
  def bool_to_byte(false), do: 0

  def byte_to_bool(1), do: true
  def byte_to_bool(0), do: false

  defp generate_serialize() do
    quote do
      def serialize(val) do
        serialize_field(0, val, <<>>)
      end
    end
  end

  defp generate_field_serializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      serializer(type, varname, ix)
    end)
  end

  defp generate_deserialize() do
    quote do
      def deserialize(str, template \\ __struct__) do
        deserialize_field(str, template)
      end
    end
  end

  defp generate_field_deserializers(thrift_def) do
    Enum.with_index(thrift_def ++ [final: nil])
    |> Enum.map(fn({{k, v}, ix}) ->
      type = v
      varname = k
      deserializer(type, varname, ix)
    end)
  end

  defp header(type, ix) do
    quote do
      << unquote(Type.id(type)), unquote(ix) + 1 :: 16-unsigned >>
    end
  end

  defp value_serializer(:bool, var) do
    quote do
      << Thrash.Protocol.Binary.bool_to_byte(unquote(Macro.var(var, __MODULE__))) :: 8-unsigned >>
    end
  end
  defp value_serializer(:double, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: signed-float >>
    end
  end
  defp value_serializer(:i32, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 32-signed >>
    end
  end
  defp value_serializer({:enum, enum_module}, var) do
    quote do
      << unquote(enum_module).id(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned >>
    end
  end
  defp value_serializer(:i64, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 64-signed >>
    end
  end
  defp value_serializer(:string, var) do
    quote do
      << byte_size(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned,
      unquote(Macro.var(var, __MODULE__)) :: binary >>
    end
  end
  defp value_serializer({:struct, struct_module}, var) do
    quote do
      unquote(struct_module).serialize(unquote(Macro.var(var, __MODULE__)))
    end
  end
  defp value_serializer({:list, of_type}, var) do
    quote do
      << unquote(Type.id(of_type)),
      length(unquote(Macro.var(var, __MODULE__))) :: 32-unsigned >> <>
      (Enum.map(unquote(Macro.var(var, __MODULE__)),
            fn(v) -> unquote(value_serializer(of_type, :v)) end)
       |> Enum.join)
    end
  end

  defp list_deserializer(type, lengthvar, restvar) do
    quote do
      list_deserializer = fn
        (0, {acc, rest}, _recurser) -> {Enum.reverse(acc), rest}
        (n, {acc, str}, recurser) ->
          unquote(splice_binaries(value_matcher(type, :value), quote do: << rest :: binary >>)) = str
          {value, rest} = unquote(value_mapper(type, :value, :rest))
          recurser.(n - 1, {[value | acc], rest}, recurser)
      end
      list_deserializer.(unquote(Macro.var(lengthvar, __MODULE__)),
                         {[], unquote(Macro.var(restvar, __MODULE__))},
                         list_deserializer)
    end
  end


  defp deserializer(nil, :final, _ix) do
    quote do
      def deserialize_field(<< 0, remainder :: binary >>, acc), do: {acc, remainder}
    end
  end
  defp deserializer(type, fieldname, ix) do
    quote do
      def deserialize_field(
            unquote(splice_binaries(header(type, ix),
                                    value_matcher(type, :value))
                    |> splice_binaries(quote do: << rest :: binary >>)), acc) do
        {value, rest} = unquote(value_mapper(type, :value, :rest))
        deserialize_field(rest, Map.put(acc,
                                        unquote(fieldname),
                                        value))
      end
    end
  end

  defp value_matcher(:bool, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 8-unsigned >>
    end
  end
  defp value_matcher({:enum, _enum_module}, var) do
    quote do
      << unquote(Macro.var(var, __MODULE__)) :: 32-signed >>
    end
  end
  defp value_matcher(:string, var) do
    quote do
      << len :: 32-unsigned, unquote(Macro.var(var, __MODULE__)) :: size(len)-binary >>
    end
  end
  defp value_matcher({:struct, _struct_module}, _var) do
    quote do
      << >>
    end
  end
  defp value_matcher({:list, of_type}, var) do
    # "var" will be the length of the list
    quote do
      << unquote(Type.id(of_type)), unquote(Macro.var(var, __MODULE__)) :: 32-unsigned >>
    end
  end
  defp value_matcher(type, var) do
    # for "simple" values, we can use the same pattern that value_serializer generates
    value_serializer(type, var)
  end

  defp value_mapper(:bool, var, rest) do
    quote do
      {Thrash.Protocol.Binary.byte_to_bool(unquote(Macro.var(var, __MODULE__))),
       unquote(Macro.var(rest, __MODULE__))}
    end
  end
  defp value_mapper({:enum, enum_module}, var, rest) do
    quote do
      {unquote(enum_module).atom(unquote(Macro.var(var, __MODULE__))),
       unquote(Macro.var(rest, __MODULE__))}
    end
  end
  defp value_mapper({:struct, struct_module}, _var, rest) do
    quote do
      unquote(struct_module).deserialize(unquote(Macro.var(rest, __MODULE__)))
    end
  end
  defp value_mapper({:list, of_type}, var, rest) do
    list_deserializer(of_type, var, rest)
  end
  defp value_mapper(_type, val, rest) do
    # note the tuple is the same as its quoted value, so we don't need
    # to quote/unquote here
    {Macro.var(val, __MODULE__), Macro.var(rest, __MODULE__)}
  end

  defp empty_value?({:struct, struct_module}) do
    quote do
      value == nil || value == unquote(struct_module).__struct__
    end
  end
  defp empty_value?({:list, _}) do
    quote do
      value == nil || value == []
    end
  end
  defp empty_value?(_) do
    quote do
      value == nil
    end
  end

  defp splice_binaries({:<<>>, _, p1}, {:<<>>, _, p2}) do
    {:<<>>, [], p1 ++ p2}
  end
  defp splice_binaries(b1, b2) do
    quote do: unquote(b1) <> unquote(b2)
  end

  defp serializer(nil, :final, ix) do
    quote do
      def serialize_field(unquote(ix), _, acc), do: acc <> << 0 >>
    end
  end
  defp serializer(type, fieldname, ix) do
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
