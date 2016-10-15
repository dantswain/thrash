defmodule TacoType do
  use Thrash.Enumerated
end

defmodule TacoFlavor do
  use Thrash.Enumerated, source: TacoType
end

defmodule SubStruct do
  use Thrash.Protocol.Binary
end

#defmodule Constants do
#  use Thrash.Constants
#end
#
#defmodule SimpleStruct do
#  use Thrash.Protocol.Binary, defaults: [taco_pref: :chicken],
#                              types: [taco_pref: {:enum, TacoType}]
#end

#defmodule InnerStruct do
#  use Thrash.Protocol.Binary, source: SubStruct
#end
#
#defmodule OuterStruct do
#  use Thrash.Protocol.Binary, source: SimpleStruct,
#                              defaults: [taco_pref: :chicken,
#                                         sub_struct: %InnerStruct{}],
#                              types: [taco_pref: {:enum, TacoType},
#                                      sub_struct: {:struct, InnerStruct}]
#end
