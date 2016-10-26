defmodule Thrash.ThriftMetaTest do
  use ExUnit.Case

  alias Thrash.IDL

  @idl_pattern Path.expand("../thrift", __DIR__) <> "**/*.thrift"
  @idl_files Path.wildcard(@idl_pattern)

  test "read_constants works" do
    idl = IDL.parse(@idl_files)

    expected = %{
      max_things: 42,
      const_substruct: %SubStruct{sub_id: 9, sub_name: "number 9"},
      const_substruct_list: [%SubStruct{sub_id: 10, sub_name: "number 10"}],
      const_substruct_map: %{1 => %SubStruct{sub_id: 1}}
    }
    got = Thrash.ThriftMeta.read_constants(idl, nil)

    assert expected == got
  end

  test "read_enum works" do
    idl = IDL.parse(@idl_files)

    expected = %{barbacoa: 123,
                 carnitas: 124,
                 steak: 125,
                 chicken: 126,
                 pastor: 127}

    got = Thrash.ThriftMeta.read_enum(idl, TacoType)
    assert expected == got

    got = Thrash.ThriftMeta.read_enum(idl, TACOTYPE)
    assert expected == got

    got = Thrash.ThriftMeta.read_enum(idl, ThrashFoo.TacoType)
    assert expected == got
  end

  test "read_enum raises an error if the enum is not found" do
    idl = IDL.parse(@idl_files)

    assert_raise ArgumentError, fn ->
      Thrash.ThriftMeta.read_enum(idl, BurritoType)
    end
  end
end
