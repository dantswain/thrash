namespace erl thraft

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
}
