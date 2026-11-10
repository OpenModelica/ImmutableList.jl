#=
This file is part of OpenModelica.
Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
c/o Linköpings universitet, Department of Computer and Information Science,
SE-58183 Linköping, Sweden.

All rights reserved.

THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
ACCORDING TO RECIPIENTS CHOICE.

The OpenModelica software and the OSMC (Open Source Modelica Consortium)
Public License (OSMC-PL) are obtained from OSMC, either from the above
address, from the URLs: http://www.openmodelica.org or
http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
distribution. GNU version 3 is obtained from:
http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
http://www.opensource.org/licenses/BSD-3-Clause.

This program is distributed WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
CONDITIONS OF OSMC-PL.
=#

#=
Julia's collection interfaces for lists, so a list works where a Julia user expects a Vector-like
sequence: construction from any iterable, indexing, equality and hashing, `show`, and the functions
that build a new collection (`map`, `filter`, `reverse`, `sort`, `vcat`, `first`/`last` with a count)
returning lists. An empty result is `nil` (`Nil{Any}`), as everywhere in this package: code that ends
a loop at `=== nil` keeps working.
=#

"""
A list built by this file: `nil` when empty, a `Cons{T}` chain otherwise.
"""
const BuiltList{T} = Union{Nil{Any}, Cons{T}}

"""
    fromVector(v::AbstractVector{T})::BuiltList{T}

The elements of `v`, in order, as a `Cons{T}` chain ending in `nil`; `nil` when `v` is empty.
"""
function fromVector(v::AbstractVector{T})::BuiltList{T} where {T}
  local lst::BuiltList{T} = nil
  for i::Int in lastindex(v):-1:firstindex(v)
    lst = Cons{T}(v[i], lst)
  end
  return lst
end

#= Construction =#

"""
    List(itr)
    List{T}(itr)
    List{T}()

A list of the elements of an iterable (a Vector, Tuple, range, generator, Set, string, another list)
in iteration order. The element type is the one `collect` gives, or `T`. `List{T}()` is empty.
"""
ListDef.List(itr) = fromVector(collect(itr))
ListDef.List(lst::List) = lst
(::Type{ListDef.List{T}})(itr) where {T} = fromVector(collect(T, itr))
(::Type{ListDef.List{T}})(lst::Cons{T}) where {T} = lst
(::Type{ListDef.List{T}})() where {T} = nil

#= Indexing: O(i) =#

Base.firstindex(::List) = 1
Base.lastindex(lst::List) = length(lst)
Base.keys(lst::List) = Base.OneTo(length(lst))
Base.eachindex(lst::List) = Base.OneTo(length(lst))

"""
    pairs(lst::List)

`(index, element)` pairs, in one pass over the list (`findfirst`, `findall` use it).
"""
Base.pairs(lst::List) = zip(Base.OneTo(length(lst)), lst)

"""
    getindex(lst::List, i::Integer)

The `i`th element, in O(i). A `BoundsError` outside `1:length(lst)`.
"""
function Base.getindex(lst::List, i::Integer)
  if i >= 1
    local k::Int = 1
    for x in lst
      k == i && return x
      k += 1
    end
  end
  throw(BoundsError(lst, i))
end

"""
    getindex(lst::List, r::AbstractUnitRange{<:Integer})

The elements at the indices `r` as a list. When `r` runs to the end, the result shares the list's
cells (`lst[2:end]` is the tail, no copy).
"""
function Base.getindex(lst::List, r::AbstractUnitRange{<:Integer})
  local n::Int = length(lst)
  isempty(r) && return nil
  (first(r) >= 1 && last(r) <= n) || throw(BoundsError(lst, r))
  local rest = lst
  for _ in 2:first(r)
    rest = rest.tail
  end
  last(r) == n && return rest
  return first(rest, length(r))
end

#= First, last, tail =#

"""
    tail(lst::List)

The list without its first element, in O(1): the list `listRest` returns. `tail(nil)` is `nil`.
`tail` of anything else is `Base.tail` (tuples). A function of its own rather than a `Base.tail`
method: a method on `Base.tail` invalidates Base's compiled `iterate(::Enumerate, ::Any)`.
"""
tail(lst::Cons) = lst.tail
tail(lst::Nil) = lst
tail(x) = Base.tail(x)

"""
    last(lst::List)

The last element, in O(n). `last(nil)` is `nil`.
"""
function Base.last(lst::Cons)
  local x = lst.head
  for y in lst.tail
    x = y
  end
  return x
end

"""
    first(lst::List, n::Integer)

The first `n` elements (all when the list is shorter) as a list.
"""
function Base.first(lst::Cons{T}, n::Integer) where {T}
  n < 0 && throw(ArgumentError("Number of elements must be non-negative"))
  local v::Vector{T} = collect(T, Iterators.take(lst, n))
  return length(v) == length(lst) ? lst : fromVector(v)
end
function Base.first(lst::Nil, n::Integer)
  n < 0 && throw(ArgumentError("Number of elements must be non-negative"))
  return lst
end

"""
    last(lst::List, n::Integer)

The last `n` elements (all when the list is shorter) as a list: the list's own cells, no copy.
"""
function Base.last(lst::List, n::Integer)
  n < 0 && throw(ArgumentError("Number of elements must be non-negative"))
  local rest = lst
  for _ in 1:(length(lst) - n)
    rest = rest.tail
  end
  return n == 0 ? nil : rest
end

"""
    rest(lst::List[, state])

What `x, rest... = lst` binds to `rest`: the remaining list, no copy.
"""
Base.rest(lst::List) = lst
Base.rest(::List, state::List) = state

#= Functions that build a new collection return a list =#

"""
    map(f, lst::List, lsts::List...)

`f` applied to the elements (to the elements at the same position of each list, up to the shortest),
as a list. The element type is the one `map` gives for a Vector.
"""
function Base.map(f, lst::List, lsts::List...)
  local v::Vector = collect(Base.Generator(f, lst, lsts...))
  return isempty(v) ? nil : fromVector(v)
end

"""
    filter(f, lst::List)

The elements for which `f` is true, in order, as a list of the same element type.
"""
function Base.filter(f, lst::Cons{T}) where {T}
  local v::Vector{T} = T[]
  for x in lst
    f(x) && push!(v, x)
  end
  return length(v) == length(lst) ? lst : fromVector(v)
end
Base.filter(f, ::Nil) = nil

"""
    reverse(lst::List)
    Iterators.reverse(lst::List)

The elements in reverse order, as a list (`listReverse`). `foldr` and `Iterators.reverse` use it.
"""
Base.reverse(lst::List) = listReverse(lst)
Base.Iterators.reverse(lst::List) = listReverse(lst)

"""
    vcat(lsts::List...)

The elements of the lists one after the other, as a list. The element type is promoted as for
Vectors (empty lists do not count); the last list is shared when it has that type.
"""
function Base.vcat(lst::List, lsts::List...)
  local all::Tuple = (lst, lsts...)
  local S::Type = Union{}
  for l in all
    l isa Cons && (S = promote_type(S, eltype(l)))
  end
  S === Union{} && return nil
  local out::BuiltList{S} = nil
  local lastList = all[end]
  local start::Int = length(all)
  if lastList isa Cons{S}
    out = lastList
    start -= 1
  end
  for i::Int in start:-1:1
    for x in listReverse(all[i])
      out = Cons{S}(convert(S, x), out)
    end
  end
  return out
end

"""
    sort(lst::List; kws...)

The elements sorted, as a list; the keywords are `sort`'s (`by`, `lt`, `rev`, `order`).
`sort(lst, f)` keeps MetaModelica's meaning: `f(a, b)` true means `a` comes after `b`.
"""
function Base.sort(lst::Cons{T}; kws...) where {T}
  return fromVector(sort!(collect(lst); kws...))
end
Base.sort(::Nil; kws...) = nil

"""
    empty(lst::List)

An empty list (`nil`).
"""
Base.empty(::List) = nil

"""
    copy(lst::List)

The list itself: lists are immutable.
"""
Base.copy(lst::List) = lst

#= Equality and hashing: element by element, as for Vectors =#

"""
    ==(a::List, b::List)

True when both have the same length and equal elements (`missing` when an element comparison is
`missing` and none is false). Element types do not matter: `list(1) == list(1.0)`, and every empty
list equals `nil`.
"""
function Base.:(==)(a::List, b::List)
  length(a) == length(b) || return false
  local anymissing::Bool = false
  for (x, y) in zip(a, b)
    local eq = x == y
    if eq === missing
      anymissing = true
    elseif !eq
      return false
    end
  end
  return anymissing ? missing : true
end

"""
    isequal(a::List, b::List)

As `==`, element by element with `isequal`.
"""
function Base.isequal(a::List, b::List)::Bool
  length(a) == length(b) || return false
  for (x, y) in zip(a, b)
    isequal(x, y) || return false
  end
  return true
end

"""
Seed of a list's hash, so a list and a Vector with the same elements hash differently.
"""
const LIST_HASH_SEED = 0x6d35bb51952d5539 % UInt

"""
    hash(lst::List, h::UInt)

The elements' hashes combined in order, consistent with `isequal`.
"""
function Base.hash(lst::List, h::UInt)::UInt
  local acc::UInt = hash(LIST_HASH_SEED, h)
  for x in lst
    acc = hash(x, acc)
  end
  return acc
end

#= Printing =#

"""
    show(io::IO, lst::List)

`list{T}[a, b, c]`, the elements shown as in a Vector. `string(lst)` keeps its own format.
"""
function Base.show(io::IO, lst::List)
  print(io, "list{", eltype(lst), "}[")
  local firstElement::Bool = true
  for x in lst
    firstElement || print(io, ", ")
    show(io, x)
    firstElement = false
  end
  print(io, "]")
end
Base.show(io::IO, ::MIME"text/plain", lst::List) = show(io, lst)

export tail
