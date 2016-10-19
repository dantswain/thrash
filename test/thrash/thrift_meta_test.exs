defmodule Thrash.ThriftMetaTest do
  use ExUnit.Case

  @idl_pattern Path.expand("../thrift", __DIR__) <> "**/*.thrift"
  @idl_files Path.wildcard(@idl_pattern)

  setup do
    existing_idl = Application.get_env(:thrash, :idl_files)

    on_exit fn ->
      Application.put_env(:thrash, :idl_files, existing_idl)
    end
  end

  test "read_constants works" do
    idl = Thrash.ThriftMeta.parse_idl(@idl_files)

    expected = %{max_things: 42,
                 const_substruct: %SubStruct{sub_id: 9, sub_name: "number 9"}}
    got = Thrash.ThriftMeta.read_constants(idl, nil)

    assert expected == got
  end

  test "read_enum works" do
    idl = Thrash.ThriftMeta.parse_idl(@idl_files)

    expected = %{barbacoa: 123,
                 carnitas: 124,
                 steak: 125,
                 chicken: 126,
                 pastor: 127}

    got = Thrash.ThriftMeta.read_enum(idl, TacoType)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(idl, TACOTYPE)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(idl, ThrashFoo.TacoType)
    assert {:ok, expected} == got
  end

  test "read_enum returns {:error, %{} if the enum is not found" do
    idl = Thrash.ThriftMeta.parse_idl(@idl_files)

    assert {:error, %{}} == 
      Thrash.ThriftMeta.read_enum(idl, BurritoType)
  end

  test "reading multiplie thrift IDL files" do
    thrift_idl = Thrash.ThriftMeta.parse_idl(@idl_files)
    assert %Thrift.Parser.Models.Schema{} = thrift_idl
    assert [:TacoType] == Map.keys(thrift_idl.enums)
    assert [:SimpleStruct, :SubStruct] == Map.keys(thrift_idl.structs)

    # use app env by default
    Application.put_env(:thrash, :idl_files, @idl_files)
    assert thrift_idl == Thrash.ThriftMeta.parse_idl
  end

  test "reading idl fails if there are no idl files" do
    Application.put_env(:thrash, :idl_files, nil)
    assert_raise ArgumentError, fn ->
      _ = Thrash.ThriftMeta.parse_idl
    end

    Application.put_env(:thrash, :idl_files, [])
    assert_raise ArgumentError, fn ->
      _ = Thrash.ThriftMeta.parse_idl
    end
  end
end
