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
