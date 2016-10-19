defmodule Thrash.ConstantsTest do
  use ExUnit.Case

  test "generating constants" do
    assert 42 == Constants.max_things

    assert %SubStruct{sub_id: 9, sub_name: "number 9"} == Constants.const_substruct
  end
end
