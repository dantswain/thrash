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

defmodule Namespaced do
  defmodule AStruct do
    use Thrash.Protocol.Binary, source: SubStruct
  end
  

  defmodule BStruct do
    use Thrash.Protocol.Binary, source: SimpleStruct,
                                defaults: [taco_pref: :chicken,
                                           sub_struct: %Namespaced.AStruct{}],
                                types: [taco_pref: {:enum, TacoType},
                                        sub_struct: {:struct, Namespaced.AStruct}]
  end
end
