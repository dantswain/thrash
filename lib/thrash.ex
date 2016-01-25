defmodule Thrash do
  defmodule Type do
    def id(:i32), do: 8
    def id(:string), do: 11

    defmacro i32,    do: quote do: 8
    defmacro string, do: quote do: 11
  end

  defmodule BinaryAcceleratedProtocol do
    require Thrash.Type

    defmacro generate_deserializer(struct_def) do
      Enum.with_index(struct_def)
      |> Enum.map(fn({{k, v}, ix}) ->
        type = v
        varname = k
        type_id = Type.id(type)
        fn_name = String.to_atom("deserialize_" <> Atom.to_string(varname))
        deserializer(type_id, fn_name, ix)
      end)
    end

    def deserializer(type_id = Type.i32, fn_name, ix) do
      quote do
        def unquote(fn_name)(<<unquote(type_id), unquote(ix + 1) :: 16-unsigned, value :: 32-signed, rest :: binary>>) do
          {value, rest}
        end
      end
    end
    def deserializer(type_id = Type.string, fn_name, ix) do
      quote do
        def unquote(fn_name)(<< unquote(type_id), unquote(ix + 1) :: 16-unsigned, len :: 32-unsigned, value :: size(len)-binary, 0, rest :: binary>>) do
          {value, rest}
        end
      end
    end
  end
end
