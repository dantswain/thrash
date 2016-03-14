# Thrash

[![Build Status](https://travis-ci.org/dantswain/thrash.svg?branch=master)](https://travis-ci.org/dantswain/thrash)

An Elixir library for serialization and deserialization of
[Apache Thrift](https://thrift.apache.org/) messages. 🤘

## Philosophy

Thrash is an attempt to provide faster serialization/deserialization
to/from Thrift's Binary protocols and to provide an API that is
idiomatic for Elixir applications.  Compared to the official Erlang
Thrift library, Thrash is significantly faster (see below) and works
with Elixir structs rather than Erlang records.

Thrash makes heavy use of binary pattern matching and uses Elixir
macros to flatten much of the branching logic that exists in the
Erlang library.  For example, we can use a macro to generate a single
binary match specification to extract the typed value of a field from
our message as opposed to first extracting the field number and then
looking up its type and then performing the appropriate value
extraction.

Thrash is geared towards use cases where Thrift is being used
primarily as a message format specification, as opposed to a service
platform.  Thrash does not currently provide an implementation of
Thrift Server and may not plug easily into an existing Thrift service
without a server adapter.  On the other hand, if you are using Thrift
as a message specification within your own services, Thrash can
provide a significant speedup.

It should be possible to extend Thrash to plug into Thrift services
(i.e., provide a Thrift Server implementation).  I simply haven't put
any effort into implementing that because it doesn't fit my use case.

## Usage

Suppose we have a thrift file containing the following (taken from
[test/thrash_test.thrift](test/thrash_test.thrift)).

    namespace erl thrash

    const i32 MAX_THINGS = 42
    
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
    }

First, generate the Erlang thrift code.

    thrift -o src --gen erl test/thrash_test.thrift

This should place .erl and .hrl files the src/gen-erl directory.

Next, create Elixir modules to encapsulate these data structures and
`use` the proper Thrash mixins to automatically generate code at
compile-time (taken from
[test/simple_struct.ex](test/simple_struct.ex)).

    defmodule TacoType do
      use Thrash.Enumerated
    end
    
    defmodule SubStruct do
      use Thrash.Protocol.Binary
    end
    
    defmodule SimpleStruct do
      use Thrash.Protocol.Binary, defaults: [taco_pref: :chicken],
                                  types: [taco_pref: {:enum, TacoType}]
    end

    defmodule Constants do
      use Thrash.Constants
    end

You can then do things like the following.

    # construct a struct - note we can use an atom for the enum
    iex> simple_struct = %SimpleStruct{id: 42, name: "my thing", list_of_ints: [1, 2, 5], taco_pref: :carnitas}
    %SimpleStruct{bigint: nil, flag: false, floatval: nil, id: 42, list_of_ints: [1, 2, 5], list_of_structs: [], name: "my thing", sub_struct: %SubStruct{sub_id: nil, sub_name: nil}, taco_pref: :carnitas}

    # serialize to binary
    iex> b = SimpleStruct.serialize(simple_struct)
    <<8, 0, 1, 0, 0, 0, 42, 11, 0, 2, 0, 0, 0, 8, 109, 121, 32, 116, 104, 105, 110, 103, 15, 0, 3, 8, 0, 0, 0, 3, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 5, 2, 0, 6, 0, 8, 0, 8, 0, ...>>

    # deserialize - note we get back the atom value for the enum field
    iex> {simple_struct_deserialized, _remainder} = SimpleStruct.deserialize(b)
    {%SimpleStruct{bigint: nil, flag: false, floatval: nil, id: 42, list_of_ints: [1, 2, 5], list_of_structs: [], name: "my thing", sub_struct: %SubStruct{sub_id: nil, sub_name: nil}, taco_pref: :carnitas}, ""}

    # pulled in constants
    iex(1)> Constants.max_things
    42

See the moduledocs for `Thrash.Enumerated` and `Thrash.Protocol.Binary` for
usage details.  Note, both of these mixins accept a `source` argument
to allow you to manually define the source structure in your Thrift
IDL.

## Mix.Tasks.Compile.Thrift

Thrash provides the `compile.thrift` mix task to help with compiling
Elixir projects that use Thrift and Thrash.

See [lib/mix/tasks/compile/thrift.ex](lib/mix/tasks/compile/thrift.ex)
for detailed documentation of the compile task, including how to
modify your mix.exs file so that this task runs automatically.

## Data Types

Thrift data types are mapped to Elixir as follows.

| Thrift Type   | Elixir Type     |
| ------------- |-----------------|
| Boolean       | Boolean         |
| Byte          | Integer         |
| i16           | Integer         |
| i32           | Integer         |
| i64           | Integer         |
| Double        | Float           |
| String        | String (binary) |
| Struct        | Struct          |
| Enumerated    | Thrash.Enum     |
| Map           | Map (`%{}`)     |
| Set           | MapSet          |
| List          | List (`[]`)     |

## Status

Thrash should provide a complete solution for
serialization/deserialization via the Thrift binary protocol.  I have been
focusing on implementing the functionality that I need while leaving
the door open for other functionality.  I have no plans to implement
other protocols, but would welcome pull requests.

Thrash provides no implementation here for services or servers.  It
should be possible to build something like that using Thrash and a
third party server library.  Pull requests are welcomed.

## Benchmarks

Thrash is significantly faster at serialization/deserialization than
the official Erlang Thrift library for the Thrift Binary protocol.  In
the interest of full disclosure, this comparison is made using
[ThriftEx](https://github.com/dantswain/thrift_ex), which is an Elixir
adapter for the Erlang library that I wrote.  However, ThriftEx only
exposes the data structures generated by the Thrift generator - it
does not implement any of its own serialization or deserialization.

The bench directory in this project contains a simple benchmark for
comparing Thrash and Erlang Thrift library.  I'd welcome suggestions
on how to improve these benchmarks.

```
iex(1)> Bench.bench_thrift_ex
Benchmarking Thrift serialization
*** #Function<1.127410406/0 in Bench.bench_thrift_ex/0> ***
1.1 sec    32K iterations   34.59 μs/op

Benchmarking Thrift deserialization
*** #Function<2.127410406/0 in Bench.bench_thrift_ex/0> ***
1.0 sec    16K iterations   64.37 μs/op

Done
:ok
iex(2)> Bench.bench_thrash
Benchmarking Thrash serialization
*** #Function<4.127410406/0 in Bench.bench_thrash/0> ***
1.6 sec   262K iterations   6.23 μs/op

Benchmarking Thrash deserialization
*** #Function<5.127410406/0 in Bench.bench_thrash/0> ***
1.7 sec   524K iterations   3.39 μs/op

Done
:ok
```

According to these results, Thrash is about 5x faster for
serialization and about 18x faster for deserialization compared to the
official Erlang library.

## Thrift Version Compatibility

Note that Thrift < 0.9.3 is not compatible with Erlang/OTP R18 and
up.  Therefore, for best results, you should upgrade to at least
Thrift 0.9.3.

Your mileage may vary - the main cause of incompatibility is the
`dict` type, which the Thrift Erlang module uses for maps.  Your code
may be OK if you are not using any maps in your Thrift IDL.  If you
ARE using maps in your Thrift IDL and you are unable to upgrade
Thrift, you _might_ be able to hack in support by modifying the generated
Erlang typespecs to replace any instances of the `dict()` type with
`dict:dict()`.

## Development & Contribution

If you want to pull down this repository and poke around, check out
[test/simple_struct.ex](test/simple_struct.ex) and
[test/namespaced](test/namespaced/simple_struct.ex) to see how the API
is currently being used.

To execute the test suite, you need to first generate the erlang
source from the test thrift file.

```
# fetch deps
mix deps.fetch
# make sure the compile.thrift task is available
mix compile
# compile thrift
THRIFT_INPUT_DIR=test/ mix compile.thrift
# now tests should work
mix test
```

Standard Elixir and Github workflows apply here.  Pull requests are welcome.
