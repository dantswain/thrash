defmodule Thrash.Protocol.Binary do
  @moduledoc """
  Generates a struct and serialization/deserialization code for use
  with the Thrift binary protocol.

  Suppose you have a Thrift file with a struct:

    // in thrift file
    struct MyStruct {
      1: i32 id,
      2: string name
    }

  Create a module with a name that ends with `MyStruct` and `use` this
  module to generate a struct, a serializer, and a deserializer.

    defmodule MyApp.MyStruct do
      use Thrash.Protocol.Binary
    end

  This generates a `%MyApp.MyStruct{id: nil, name: nil}` struct and
  `MyApp.MyStruct.serialize/1` and `MyApp.MyStruct.deserialize/1`
  functions.  The type signatures of these functions are as follows.

    @spec serialize(%MyApp.MyStruct{}) :: binary
    @spec deserialize(binary) :: {%MyApp.MyStruct{}, binary}

  The second output argument of `deserialize/1` is any part of the
  input string that is left over after deserialization.

  Note that Thrash will use the last part of the module name to search
  for a matching struct in the Thrift IDL.  I.e., `MyApp.MyStruct`,
  `MyApp.Foo.MyStruct` and `MyStruct` modules will all match a Thrift
  struct called `MyStruct`.  To manually specify a source struct, use
  the `:source` option described below.

  The `use` macro accepts a keyword list argument with the following
  options.

    * `:source` - Use this to manually specify a source struct in your
       Thrift IDL.  The value should be an atom (Elixir module names
       will work).
    * `:defaults` - A keyword list specifying the default value overrides for
       struct fields.  The key is a field name atom and the value will
       be used as a default for that struct field.  If no default is
       specified in the Thrift IDL or
       via the `:defaults` option, the default struct value will be
       `nil` for scalar fields, `[]` for lists, and an empty struct
       of the appropriate type for struct fields.
    * `:types` - A keyword list specifying type overrides.  For the
       most part, Thrash should automatically detect types from the
       Thrift IDL.  One special case is enum values, which are
       specified in the generated Erlang code as 32-bit integers -
       thus, it is necessary to manually specify Enumerated values if
       you wish to use Thrash.Enumerated with them to get
       atoms for values rather than integers.
  """

  alias Thrash.Type
  alias Thrash.MacroHelpers

  defmacro __using__(opts) do
    source_module = Keyword.get(opts, :source)
    defaults = Keyword.get(opts, :defaults, [])
    types = Keyword.get(opts, :types, [])
    modulename = MacroHelpers.determine_module_name(source_module, __CALLER__)

    thrift_def = Thrash.StructDef.find_in_thrift(modulename)
    |> Thrash.StructDef.override_types(types)

    [generate_struct(modulename, types, defaults)] ++
      [generate_serialize()] ++
      [generate_deserialize()] ++
      generate_field_serializers(thrift_def) ++
      generate_field_deserializers(thrift_def)
  end

  def bool_to_byte(true), do: 1
  def bool_to_byte(false), do: 0

  def byte_to_bool(1), do: true
  def byte_to_bool(0), do: false

  defp generate_struct(modulename, types, defaults) do
    quote do
      defstruct(Thrash.StructDef.find_in_thrift(unquote(modulename))
                |> Thrash.StructDef.override_types(unquote(types))
                |> Thrash.StructDef.override_defaults(unquote(defaults))
                |> Thrash.StructDef.to_defstruct)
    end
  end

  defp generate_serialize() do
    quote do
      def serialize(val) do
        serialize_field(0, val, <<>>)
      end
    end
  end

  defp generate_field_serializers(thrift_def) do
    Enum.with_index(thrift_def ++ [Thrash.StructDef.Field.finalizer])
    |> Enum.map(fn({field, ix}) -> serializer(field.type, field.name, ix) end)
  end

  defp generate_deserialize() do
    quote do
      def deserialize(str, template \\ __struct__) do
        deserialize_field(str, template)
      end
    end
  end

  defp generate_field_deserializers(thrift_def) do
    Enum.with_index(thrift_def ++ [Thrash.StructDef.Field.finalizer])
    |> Enum.map(fn({field, ix}) -> deserializer(field.type, field.name, ix) end)
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
