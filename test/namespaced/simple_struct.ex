defmodule Namespaced.TacoType do
  use Thrash.Enumerated
end

defmodule Namespaced.SubStruct do
  use Thrash.Protocol.Binary
end

defmodule Namespaced.SimpleStruct do
  use Thrash.Protocol.Binary, defaults: [taco_pref: :chicken],
                              types: [taco_pref: {:enum, TacoType}]
end
