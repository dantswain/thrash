defmodule Thrash.ConstantsTest do
  use ExUnit.Case

  test "generating constants" do
    assert 42 == Constants.max_things
  end
end
