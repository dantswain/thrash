include "simple_struct.thrift"

const i32 MAX_THINGS = 42

const SubStruct const_substruct = {"sub_id": 9, "sub_name": "number 9"}
const list<SubStruct> const_substruct_list = [{"sub_id": 10, "sub_name": "number 10"}]
const map<i32, SubStruct> const_substruct_map = {1: {"sub_id": 1}}
