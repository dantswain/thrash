defmodule Thrash.BinaryPropertiesTest do
  use ExUnit.Case, async: false
  use ExCheck

  @max_signed_byte trunc(:math.pow(2, 4) - 1)
  @max_signed_i16 trunc(:math.pow(2, 8) - 1)
  @max_signed_i32 trunc(:math.pow(2, 16) - 1)
  @max_signed_i64 trunc(:math.pow(2, 32) - 1)

  def cycle_serialization(module, value) do
    value
    |> module.serialize
    |> module.deserialize
  end

  property "SubStruct" do
    for_all {
      sub_id,
      sub_name
    } in {
      oneof([choose(-@max_signed_i32, @max_signed_i32), nil]),
      oneof([unicode_binary, nil])
    } do
      sub_struct = %SubStruct{sub_id: sub_id, sub_name: sub_name}
      {got_sub_struct, ""} = SubStruct.deserialize(SubStruct.serialize(sub_struct))
      sub_struct == got_sub_struct
    end
  end

  @tag iterations: 200
  property "SimpleStruct" do
    for_all {
      id,
      name,
      list_of_ints,
      bigint,
      sub_id,
      sub_name,
      flag,
      floatval,
      taco_pref,
      list_of_structs,
      chew,
      mediumint,
      map_int_to_string,
      map_string_to_struct,
      set_of_strings,
    } in {
      oneof([choose(-@max_signed_i32, @max_signed_i32), nil]),
      oneof([unicode_binary, nil]),
      list(choose(-@max_signed_i32, @max_signed_i32)),
      oneof([choose(-@max_signed_i64, @max_signed_i64), nil]),
      oneof([choose(-@max_signed_i32, @max_signed_i32), nil]),
      oneof([unicode_binary, nil]),
      bool,
      oneof([real, nil]),
      elements(TacoType.atoms),
      list({int, unicode_binary}),
      oneof([choose(-@max_signed_byte, @max_signed_byte), nil]),
      oneof([choose(-@max_signed_i16, @max_signed_i16), nil]),
      list({choose(-@max_signed_i32, @max_signed_i32), unicode_binary}),
      list({unicode_binary, int, unicode_binary}),
      list(unicode_binary),
    } do
      sub_struct = %SubStruct{sub_id: sub_id, sub_name: sub_name}
      list_of_structs = list_of_structs
      |> Enum.map(fn({sid, sname}) ->
        %SubStruct{sub_id: sid, sub_name: sname}
      end)
      map_int_to_string = Enum.into(map_int_to_string, %{})
      map_string_to_struct = map_string_to_struct
      |> Enum.reduce(%{}, fn({key, sid, sname}, acc) ->
        Map.put(acc, key, %SubStruct{sub_id: sid, sub_name: sname})
      end)
      set_of_strings = set_of_strings
      |> Enum.reduce(MapSet.new, fn(el, acc) ->
        MapSet.put(acc, el)
      end)
      struct = %SimpleStruct{
        id: id,
        name: name,
        list_of_ints: list_of_ints,
        sub_struct: sub_struct,
        flag: flag,
        floatval: floatval,
        taco_pref: taco_pref,
        list_of_structs: list_of_structs,
        chew: chew,
        mediumint: mediumint,
        map_int_to_string: map_int_to_string,
        map_string_to_struct: map_string_to_struct,
        set_of_strings: set_of_strings
      }
      {got_struct, ""} = cycle_serialization(SimpleStruct, struct)
      struct == got_struct
    end
  end
end
