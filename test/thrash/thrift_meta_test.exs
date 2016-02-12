defmodule Thrash.ThriftMetaTest do
  use ExUnit.Case

  @gen_erl  Path.expand("../../src/gen-erl", __DIR__)

  test "erl_gen_path works" do
    assert @gen_erl == Thrash.ThriftMeta.erl_gen_path()
  end

  test "types_headers works" do
    assert [Path.join(@gen_erl, "thrash_test_types.hrl")] ==
      Thrash.ThriftMeta.types_headers(Thrash.ThriftMeta.erl_gen_path())
  end

  test "read_constants works" do
    [header] = Thrash.ThriftMeta.types_headers(Thrash.ThriftMeta.erl_gen_path())

    expected = [THRASH_TEST_TACOTYPE_BARBACOA: 123,
                THRASH_TEST_TACOTYPE_CARNITAS: 124,
                THRASH_TEST_TACOTYPE_STEAK: 125,
                THRASH_TEST_TACOTYPE_CHICKEN: 126,
                THRASH_TEST_TACOTYPE_PASTOR: 127] |> Enum.into(HashSet.new)
    got = Thrash.ThriftMeta.read_constants(header) |> Enum.into(HashSet.new)

    assert Set.equal?(expected, got), "#{inspect expected} was not eq #{inspect got}"
  end

  test "read_enum works" do
    [header] = Thrash.ThriftMeta.types_headers(Thrash.ThriftMeta.erl_gen_path())

    expected = %{barbacoa: 123,
                 carnitas: 124,
                 steak: 125,
                 chicken: 126,
                 pastor: 127}

    got = Thrash.ThriftMeta.read_enum(header, TacoType)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(header, TACOTYPE)
    assert {:ok, expected} == got

    got = Thrash.ThriftMeta.read_enum(header, ThrashFoo.TacoType)
    assert {:ok, expected} == got
  end

  test "read_enum returns {:error, %{} if the enum is not found" do
    [header] = Thrash.ThriftMeta.types_headers(Thrash.ThriftMeta.erl_gen_path())

    assert {:error, %{}} == 
      Thrash.ThriftMeta.read_enum(header, BurritoType)
  end
end
