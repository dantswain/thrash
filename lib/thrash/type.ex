defmodule Thrash.Type do
  @moduledoc false

  # Translation of type specifiers to Thrift type ids
  # Thrash internal use only

  @type type_specifier :: :bool |
                          :byte |
                          :double |
                          :i16 |
                          :i32 |
                          :enum |
                          {:enum, term} |
                          :i64 |
                          :string |
                          :struct |
                          {:struct, term} |
                          :map |
                          {:map, term, term} |
                          :set |
                          {:set, term} |
                          :list |
                          {:list, term}

  @doc """
  Return the Thrift type id of a type specifier

  See thrift_constants.hrl in the
  [Thrift repo](https://github.com/apache/thrift)
  """
  @spec id(type_specifier) :: non_neg_integer
  def id(:bool), do: 2
  def id(:byte), do: 3
  def id(:double), do: 4
  def id(:i16), do: 6
  def id(:i32), do: 8
  def id(:enum), do: 8        # enum are stored as i32
  def id({:enum, _}), do: 8   # enum are stored as i32
  def id(:i64), do: 10
  def id(:string), do: 11
  def id(:struct), do: 12
  def id({:struct, _}), do: 12
  def id(:map), do: 13
  def id({:map, {_, _}}), do: 13
  def id(:set), do: 14
  def id({:set, _}), do: 14
  def id(:list), do: 15
  def id({:list, _}), do: 15
end
