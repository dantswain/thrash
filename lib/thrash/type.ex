defmodule Thrash.Type do
  def id(:bool), do: 2
  def id(:double), do: 4
  def id(:i32), do: 8
  def id(:enum), do: 8      # enum are stored as i32
  def id(:i64), do: 10
  def id(:string), do: 11
  def id(:struct), do: 12
  def id(:list), do: 15
end
