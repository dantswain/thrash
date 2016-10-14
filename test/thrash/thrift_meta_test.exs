defmodule Thrash.ThriftMetaTest do
  use ExUnit.Case

  @idl_file Path.expand("../thrash_test.thrift", __DIR__)

  test "read_constants works" do
    # FIXME
    expected = %{MAX_THINGS: 42,
                 const_substruct: [{'sub_id', 9}, {'sub_name', 'number 9'}]}
    got = Thrash.ThriftMeta.read_constants(@idl_file)

    assert expected == got
  end

  test "read_enum works" do
    expected = %{barbacoa: 123,
                 carnitas: 124,
                 steak: 125,
                 chicken: 126,
                 pastor: 127}

    got = Thrash.ThriftMeta.read_enum(@idl_file, TacoType)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(@idl_file, TACOTYPE)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(@idl_file, ThrashFoo.TacoType)
    assert {:ok, expected} == got
  end

  test "read_enum returns {:error, %{} if the enum is not found" do
    assert {:error, %{}} == 
      Thrash.ThriftMeta.read_enum(@idl_file, BurritoType)
  end
end
