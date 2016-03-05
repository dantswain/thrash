# Thrash

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

See the moduledocs for `Thrash.Enumerated` and `Thrash.Protocol.Binary` for
usage details.  Note, both of these mixins accept a `source` argument
to allow you to manually define the source structure in your Thrift
IDL.

## Status

Thrash is very much still a work in progress.  I have been focusing on
implementing the functionality that I need.

* Many of the basic thrift data types are implemented: bool, double,
  i32, enum, i64, string, struct, and list.  Adding support for other
  data types should be relatively easy with the possible exceptions of
  map and set.

* I haven't finalized the API for reading from the thrift IDL, but it
  is coming along.

* I have been focused on Thrift Binary Protocol because that is what
  my use case needs and what the official Erlang library implements and
  I want to be able to do benchmark comparisons.  I have no plans to
  implement other protocols, but would welcome pull requests.

* There is no implementation here for services or servers.  It should
  be possible to build something like that using Thrash.  Pull
  requests are welcomed.

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

## Development & Contribution

If you want to pull down this repository and poke around, check out
[test/simple_struct.ex](test/simple_struct.ex) and
[test/namespaced](test/namespaced/simple_struct.ex) to see how the API
is currently being used.

Standard Elixir and Github workflows apply here.  Pull requests are welcome.
