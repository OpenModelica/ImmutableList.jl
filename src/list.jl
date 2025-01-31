/#
 # This file is part of OpenModelica.
 #
 # Copyright (c) 1998-Current year, Open Source Modelica Consortium (OSMC),
 # c/o Linköpings universitet, Department of Computer and Information Science,
 # SE-58183 Linköping, Sweden.
 #
 # All rights reserved.
 #
 # THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 # THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 # ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 # RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 # ACCORDING TO RECIPIENTS CHOICE.
 #'
 # The OpenModelica software and the Open Source Modelica
 # Consortium (OSMC) Public License (OSMC-PL) are obtained
 # from OSMC, either from the above address,
 # from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 # http://www.openmodelica.org, and in the OpenModelica distribution.
 # GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 #
 # This program is distributed WITHOUT ANY WARRANTY; without
 # even the implied warranty of  MERCHANTABILITY or FITNESS
 # FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 # IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 #
 # See the full OSMC Public License conditions for more details.
 #
 #/

"""
  This module provides an immutable list compatible with
  the MetaModelica list datatype. It is immutable and supports common operations
  associated with immutable single linked lists such as map and reduce.
"""
module ListDef


#=!!! Observe we only EVER create Nil{Any} !!!=#
struct Nil{T}
end


#= if the head element is nil the list is empty.=#
const nil = Nil{Any}()
list() = nil

struct Cons{T}
  head::T
  tail::Union{Nil, Cons{T}}
end

function Cons{T}(C::Base.Generator{UnitRange{T0}, T1}) where {T, T0, T1}
  local iter::UnitRange{T0} = C.iter
  local func::Function = C.f
  local iterRev = reverse(iter)
  local firstElem = func(first(iterRev))
  local lst::Cons{T} = Cons{T}(firstElem, nil)
  iterRev = iterRev[2:end]
  for i in iterRev
    lst = Cons{T}(func(i), lst)
  end
  return lst
end

const List{T} = Union{Nil{T}, Cons{T}, Nil}
List() = Nil{Any}()
Nil() = List()

#=
  These promotion rules might seem a bit odd. Still it is the most efficient way I found of casting immutable lists
  If someone see a better alternative to this approach please fix me :). Basically I create a new list in O(N) * C time
  with the type we cast to. Also, do not create new conversion strategies without measuring performance as they will call themselves
  recursivly
=#

""" For converting lists with more than one element"""
Base.convert(::Type{List{S}}, x::Cons{T}) where {S, T <: S} = let
  List(S, x)
end

""" For converting lists of lists """
Base.convert(::Type{T}, x::Cons) where {T <: List} = let
  if (T === Nil || T === Nil{Any})
    return x
  else
    return x isa T ? x : List(eltype(T), x)
  end
end

#= Identiy cases =#
Base.convert(::Type{List{T}}, x::Cons{T}) where {T} = x
Base.convert(::Type{Cons{T}}, x::Cons{T}) where {T} = x
Base.convert(::Type{Nil}, x::Nil) = nil

Base.promote_rule(a::Type{Cons{T}}, b::Type{Cons{S}}) where {T,S} = let
  el_same(promote_type(T,S), a, b)
end

#= Definition of eltype =#
Base.eltype(::Type{List{T}}) where {T} = let
  T
end

Base.eltype(::List{T}) where {T} = let
  T
end

Base.eltype(::Type{Cons{T}}) where {T} = let
  T
end

Base.eltype(::Type{Nil}) = let
  Nil
end

Base.eltype(::Nil) = let
  Any
end

"""
  O(1) Reverse of a nil list is nil
"""
function listReverse(inLst::Nil{T}) where {T}
  return nil
end

""" O(n) Reverses an immutable list """
function listReverse(inLst::Cons{T}) where {T}
  local outLst = Cons{T}(inLst.head, nil)
  inLst = inLst.tail
  while !isa(inLst, Nil)
    outLst = Cons{T}(inLst.head, outLst)
    inLst = inLst.tail
  end
  outLst
end

Base.isempty(lst::List{T}) where {T} = _listEmpty(lst)

""" O(1) """
function _listEmpty(lst::List{T})::Bool where {T}
  if isa(lst, Nil) true else false end;
end

""" Same as listAppend.
    However creates a list of the common abstract type instead.
    See _cons
"""
function _listAppend(lst1::List{A}, lst2 = nil::List) where {A}
  if _listEmpty(lst2)
    return lst1
  end
  if _listEmpty(lst1)
    return lst2
  end
  for c in listReverse(lst1)
    lst2 = _cons(c, lst2)
  end
  lst2
end

""" For \"Efficient\" casting... O(N) * C" """
List(T::Type #= Hack.. =#, args) = let
  if args isa Nil
    return nil
  end
  local lst1::Cons{T} = Cons{T}(convert(T, args.head) ,nil)
  if args.tail isa Nil
    return lst1
  end
  for i in args.tail
    lst1 = Cons{T}(convert(T, i), lst1)
  end
  listReverse(lst1)
end

#= Support for primitive constructs. Numbers. Integer bool e.t.c =#
function list(els::T...)::List{T} where {T <: Number}
  if @generated
    #println("Generate 1")
    lst = :(nil)
    for i in length(els):-1:1
      lst = :(Cons{$(T)}(els[$(i)], $(lst)))
    end
    return lst
  else
    #println("Generate 2")
    local lst::List{T} = nil
    for i in length(els):-1:1
      lst = Cons{T}(els[i], lst)
    end
    lst
  end
end

#= Support for strings =#
function list(els::T...)::List{T} where {T <: String}
  local lst::List{T} = nil
  for i in length(els):-1:1
    lst = Cons{T}(els[i], lst)
  end
  lst
end

#= Support hieractical constructs. Concrete elements =#
function list(a::A, b::B, els...) where {A, B}
  local S::Type = typejoin(A, B, eltype(els))
  #@assert S != Any
  if S == Any
    local msg = "The resulting list became a list of any. Please check your code if this was not intentional.\n"
    msg *= string("Involved types:", A, B)
    @warn msg
  end

  local lst::Cons{S} = Cons{S}(b, Cons{S}(a, nil))
  for i in 1:length(els)
    lst = Cons{S}(els[i], lst)
  end
  lst = listReverse(lst)
  lst
end

#= List of one element =#
function list(a::T) where {T}
  Cons{T}(a, nil)
end
include("generated.jl")

# function list(a::A, b::B) where {A, B}
#   local S::Type = typejoin(A, B)
#   # @assert S != Any
#   if  S === Any && A !== Any && B !== Any
#     @warn begin
#       "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#   end
#   Cons{S}(a, Cons{S}(b, nil))
# end



#= Support hieractical constructs. Concrete elements =#
# function list(a::A, b::B, els...) where {A, B}
#     local S::Type = typejoin(A, B, eltype(els))
#     #@assert S != Any
#     if S === Any && A !== Any && B !== Any
#       @warn "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#     local lst::Cons{S} = Cons{S}(b, Cons{S}(a, nil))
#     for i in length(els):-1:1
#       lst = Cons{S}(els[i], lst)
#     end
#     return lst
# end

#include("generated.jl")

#= To be added later.  =#
# function list(a::A, b::B) where {A, B}
#   local S::Type = typejoin(A, B)
#   # @assert S != Any
#   if  S === Any && A !== Any && B !== Any
#     @warn begin
#       "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#   end
#   Cons{S}(a, Cons{S}(b, nil))
# end
#= Support hieractical constructs. Concrete elements =#
# function list(a::A, b::B, els...) where {A, B}
#     local S::Type = typejoin(A, B, eltype(els))
#     #@assert S != Any
#     if S === Any && A !== Any && B !== Any
#       @warn "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#     local lst::Cons{S} = Cons{S}(b, Cons{S}(a, nil))
#     for i in length(els):-1:1
#       lst = Cons{S}(els[i], lst)
#     end
#     return lst
# end

#= TODO =#
# function list(a::A, b::B) where {A, B}
#   local S::Type = typejoin(A, B)
#   # @assert S != Any
#   if  S === Any && A !== Any && B !== Any
#     @warn begin
#       "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#   end
#   Cons{S}(a, Cons{S}(b, nil))
# end



#= Support hieractical constructs. Concrete elements =#
# function list(a::A, b::B, els...) where {A, B}
#     local S::Type = typejoin(A, B, eltype(els))
#     #@assert S != Any
#     if S === Any && A !== Any && B !== Any
#       @warn "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#     local lst::Cons{S} = Cons{S}(b, Cons{S}(a, nil))
#     for i in length(els):-1:1
#       lst = Cons{S}(els[i], lst)
#     end
#     return lst
# end

#include("generated.jl")

#= To be added later.  =#
# function list(a::A, b::B) where {A, B}
#   local S::Type = typejoin(A, B)
#   # @assert S != Any
#   if  S === Any && A !== Any && B !== Any
#     @warn begin
#       "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#   end
#   Cons{S}(a, Cons{S}(b, nil))
# end
#= Support hieractical constructs. Concrete elements =#
# function list(a::A, b::B, els...) where {A, B}
#     local S::Type = typejoin(A, B, eltype(els))
#     #@assert S != Any
#     if S === Any && A !== Any && B !== Any
#       @warn "Unstable Immutable List created with the following types\n $(A), $(B), $(S)"
#     end
#     local lst::Cons{S} = Cons{S}(b, Cons{S}(a, nil))
#     for i in length(els):-1:1
#       lst = Cons{S}(els[i], lst)
#     end
#     return lst
# end

#= List of two elements =#
function list(a::A, b::B) where {A, B}
  local S::Type = typejoin(A, B)
  # @assert S != Any
  if S == Any
    local msg = "The resulting list became a list of any. Please check your code if this was not intentional.\n"
    msg *= string("Involved types:", A, B)
  end

  Cons{S}(a, Cons{S}(b, nil))
end

cons(v::T, ::Nil) where {T} = Cons{T}(v, nil)
cons(v::T, l::Cons{T}) where {T} = Cons{T}(v, l)
cons(v::A, l::Cons{B}) where {A,B} = let
  C = typejoin(A,B)
  @assert C != Any
  Cons{C}(convert(C,v),convert(Cons{C},l))
end

"""
_cons is a special cons function that returns a list of the common
abstract type instead of the type of the struct itself. Using this
may avoid future type conversions on the entire list to occur.
Use this in particular in generated code where you cannot use cons
responsibly.
"""
function _cons(head::A, tail::Cons{B}) where {A,B}
  C = typejoin(A,B)
  if isabstracttype(C)
    D = supertype(C)
  else
    D = C
  end
  if isstructtype(C) && !isabstracttype(C) && isabstracttype(D)
    Cons{D}(convert(D,head),convert(List{D},tail))
  else
    Cons{C}(convert(C,head),convert(List{C},tail))
  end
end
_cons(head::T, tail::Nil) where {T} = Cons{T}(head, nil)

consExternalC(::Type{T}, v :: X, l :: List{T}) where {T, X <: T} = Cons{T}(v, l) # Added for the C interface to be happy

""" <| Right associative cons operator """
<|(v, lst::Nil)  = cons(v, nil)
<|(v, lst::Cons{T}) where{T} = cons(v, lst)
<|(v::S, lst::Cons{T}) where{T, S <: T} = cons(v, lst)

Base.length(l::Nil)::Int = 0

function Base.length(l::List)::Int
  local n::Int = 0
  for _ in l
    n += 1
  end
  n
end

Base.iterate(::Nil) = nothing
Base.iterate(x::Cons, y::Nil) = nothing
function Base.iterate(l::Cons{T}, state::List{T} = l) where {T}
  t = state.head, state.tail
  t::Tuple{T, Any}
end

"""
  For list comprehension. Unless we switch to mutable structs this is the way to go I think.
  Seems to be more efficient then what the omc currently does.
"""
list(F, C::Base.Generator) = let
  #local seqArr = collect(seq)
  local iter = C.iter
  local func::Function = C.f
  local lst = nil
  local seq = collect(iter)
  local rseq = reverse!(seq)
  for i in rseq
    lst = func(i) <| lst
  end
  return lst
end

list(C::Base.Generator) = let
  list(i->i, C)
end

"""
  Iterate over collections specialized for UnitRange
author:johti17
"""
function list(C::Base.Generator{UnitRange{T0}, T1}) where {T0, T1}
  local iter::UnitRange{T0} = C.iter
  local func::Function = C.f
  local lst = nil
  local iterRev = reverse(iter)
  for i in iterRev
    lst = func(i) <| lst
  end
  return lst
end

"""
  Specialized function for iterations over a Vector{T}.
author:johti17
"""
function list(C::Base.Generator{Vector{T0}, T1}) where {T0, T1}
  local iter::Vector{T0}=  C.iter
  local func = C.f
  local iLen = length(iter)
  if iLen == 0
    return nil
  end
  lst = _cons(func(last(C.iter)), nil)
  for i in iLen-1:-1:1
    lst = _cons((@inbounds func(iter[i])), lst)
  end
  return lst
end

 """
   Specialized function for iterations over a Cons{T}.
 author:johti17
 """
function list(C::Base.Generator{Cons{T0}, T1}) where {T0, T1}
  local iter =  C.iter
  local func = C.f
  local arr = listReverse(iter)
  local lst = nil
  for i in arr
    lst = _cons(func(i), lst)
  end
  return lst
end

"""
 Specialized function for iterations over a Nil{T}.
"""
function list(C::Base.Generator{Nil{T0}, T1}) where {T0, T1}
  return nil
end

""" Adds the ability for Julia to flatten MMlists """
list(X::Base.Iterators.Flatten) = let
  list([X...]...)
end

"""
  List Reductions
"""
list(X::Base.Generator{Base.Iterators.ProductIterator{Y}, Z}) where {Y,Z} = let
  x = collect(X)
  list(list(i...) for i in view.([x], 1:size(x, 1), :))
end

"""
Generates the transformation:
 @do_threaded_for expr with (iter_names) iterators =>
  \$expr for \$iterator_names in list(zip(\$iters...)...)
"""
function make_threaded_for(expr, iter_names, ranges)
  iterExpr::Expr = Expr(:tuple, iter_names.args...)
  rangeExpr::Expr = ranges = [ranges...][1]
  rangeExprArgs = rangeExpr.args
  :($expr for $iterExpr in [ zip($(rangeExprArgs...))... ]) |> esc
end

macro do_threaded_for(expr::Expr, iter_names::Expr, ranges...)
  make_threaded_for(expr, iter_names, ranges)
end

"""
  Sorts the list by first converting it into an array
"""
Base.sort(lst::List) = let
  list(sort(collect(lst))...)
end

"""
  Sorts the list by first converting it into an array.
  Wraps the function argument in a lambda and revert the output since
  the semantics of sorting is inverted in Julia compared to MetaModelica.
See the standard Julia sort method for more information.
"""
Base.sort(lst::List, arg::Function) = let
  function λ(x, y)
    !arg(x,y)
  end
  list(sort(collect(lst); lt = λ )...)
end

macro list(elements...)
  quote
    $(esc(list(elements...)))
  end
end

export List, list, cons, <|, nil, _cons
export @do_threaded_for, Cons, Nil, listReverse, _listAppend
export @list

end
