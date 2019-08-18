module ImmutableList.jl
include("list.jl")
import .ListDef
using .ListDef

export List, list, Nil, nil, Cons, cons @do_threaded_for, <|

end # module
