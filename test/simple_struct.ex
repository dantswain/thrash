defmodule TacoType do
  use Thrash.Enumerated
end

defmodule SubStruct do
  use Thrash.Protocol.Binary

  require Thrash.Protocol.Binary
  Thrash.Protocol.Binary.generate(:thrash_test_types, :'SubStruct')
end

defmodule SimpleStruct do
  defstruct(Thrash.read_struct_def(:thrash_test_types,
                                   :'SimpleStruct',
                                   taco_pref: :chicken))

  require Thrash.Protocol.Binary
  Thrash.Protocol.Binary.generate(:thrash_test_types,
                                  :'SimpleStruct',
                                  taco_pref: {:enum, TacoType})
end
