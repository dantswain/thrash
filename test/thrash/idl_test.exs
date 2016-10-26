defmodule Thrash.IDLTest do
  use ExUnit.Case

  @idl_pattern Path.expand("../thrift", __DIR__) <> "**/*.thrift"
  @idl_files Path.wildcard(@idl_pattern)

  alias Thrash.IDL

  setup do
    existing_idl = Application.get_env(:thrash, :idl_files)

    on_exit fn ->
      Application.put_env(:thrash, :idl_files, existing_idl)
    end
  end

  test "reading multiplie thrift IDL files" do
    thrift_idl = IDL.parse(@idl_files)
    assert %Thrift.Parser.Models.Schema{} = thrift_idl
    assert [:TacoType] == Map.keys(thrift_idl.enums)
    assert [:SimpleStruct, :SubStruct] == Map.keys(thrift_idl.structs)

    # use app env by default
    Application.put_env(:thrash, :idl_files, @idl_files)
    assert thrift_idl == IDL.parse
  end

  test "reading idl fails if there are no idl files" do
    Application.put_env(:thrash, :idl_files, nil)
    assert_raise ArgumentError, fn ->
      _ = IDL.parse
    end

    Application.put_env(:thrash, :idl_files, [])
    assert_raise ArgumentError, fn ->
      _ = IDL.parse
    end
  end
end
