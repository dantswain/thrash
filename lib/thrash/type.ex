defmodule Thrash.Type do
  @moduledoc """
  Translation of type specifiers to Thrift type ids
  """

  @type type_specifier :: :bool |
                          :byte |
                          :double |
                          :i32 |
                          :enum |
                          {:enum, term} |
                          :i64 |
                          :string |
                          :struct |
                          {:struct, term} |
                          :list |
                          {:list, term}

  @doc """
  Return the Thrift type id of a type specifier

  See [thrift_constants.hrl](https://github.com/apache/thrift/blob/6ec6860801bdc87236e636add071c4faa2ac7e4b/lib/erl/include/thrift_constants.hrl#L21)
  """
  @spec id(type_specifier) :: non_neg_integer
  def id(:bool), do: 2
  def id(:byte), do: 3
  def id(:double), do: 4
  def id(:i32), do: 8
  def id(:enum), do: 8        # enum are stored as i32
  def id({:enum, _}), do: 8   # enum are stored as i32
  def id(:i64), do: 10
  def id(:string), do: 11
  def id(:struct), do: 12
  def id({:struct, _}), do: 12
  def id(:list), do: 15
  def id({:list, _}), do: 15
end
