namespace erl thrash

const i32 MAX_THINGS = 42

enum ProperNamesForColdFizzyDrinks {
  SODA = 1
}

enum TacoType {
  BARBACOA = 123,
  CARNITAS = 124,
  STEAK = 125,
  CHICKEN = 126,
  PASTOR = 127
}

struct SubStruct {
  1: i32 sub_id
  2: string sub_name
}

struct SimpleStruct {
  1: i32 id
  2: string name
  3: list<i32> list_of_ints
  4: i64 bigint
  5: SubStruct sub_struct
  6: bool flag
  7: double floatval
  8: TacoType taco_pref
  9: list<SubStruct> list_of_structs
  10: byte chew
  11: i16 mediumint
  12: map<i32, string> map_int_to_string
  13: map<string, SubStruct> map_string_to_struct
  14: set<string> set_of_strings
}
