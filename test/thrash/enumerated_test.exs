defmodule Thrash.EnumeratedTest do
  use ExUnit.Case

  defmodule TacoType do
    use Thrash.Enumerated, %{
      barbacoa: 123,
      carnitas: 124,
      steak: 125,
      chicken: 126,
      pastor: 127}
  end

  test "Creates a lookup from atom to id" do
    assert TacoType.id(:barbacoa) == 123
  end

  test "Creates a lookup from id to atom" do
    assert TacoType.atom(125) == :steak
  end
end
