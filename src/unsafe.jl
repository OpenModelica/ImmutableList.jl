"""
Dangerous/experimental operations on immutable cons lists.
Mutate pointers in place. Use with extreme care.
"""
module Unsafe

import ..ListDef: List, Cons, Nil, nil, listReverse

@inline _value_ptr(@nospecialize(x)) = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
@inline _queue_root(parent) = ccall(:jl_gc_queue_root, Cvoid, (Any,), parent)

@generated _headOffset(::Type{Cons{T}}) where {T} = :($(Int(Base.fieldoffset(Cons{T}, 1))))
@generated _tailOffset(::Type{Cons{T}}) where {T} = :($(Int(Base.fieldoffset(Cons{T}, 2))))

""" Not possible unless we write a C list impl for Julia """
function listReverseInPlace(inList::List{T})::List{T} where {T}
  listReverse(inList)
end

function listReverseInPlaceUnsafe(inList::Nil)
  return nil
end

"""
 Unsafe implementation of list reverse in place.
 Instead of creating new cons cells we swap pointers...
"""
@noinline function listReverseInPlaceUnsafe(lst::Cons{T})::Cons{T} where {T}
  prev::Union{Nil, Cons{T}} = nil
  cur::Union{Nil, Cons{T}} = lst
  while cur isa Cons{T}
    nxt = cur.tail
    listSetRest(cur, prev)
    prev = cur
    cur = nxt
  end
  return prev::Cons{T}
end

"""
 O(1). A destructive operation changing the rest part of a cons-cell.
 Cons is mutable: this is a plain checked field store.
 NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler.
"""
@noinline function listSetRest(inConsCell::Cons{T}, inNewRest::Union{Nil, Cons{T}})::Cons{T} where {T}
  setfield!(inConsCell, :tail, inNewRest)
  return inConsCell
end

# Heterogeneous rest: a foreign chain spliced into a typed cell would have to
# convert-copy, which silently detaches the chain. Keep it a loud error.
@noinline function listSetRest(inConsCell::Cons{T}, inNewRest::Union{Nil, Cons})::Cons{T} where {T}
  T === Any || inNewRest isa Union{Nil, Cons{T}} ||
    error("listSetRest: heterogeneous rest (" * string(typeof(inNewRest)) *
          ") into a typed Cons{" * string(T) * "} cell")
  setfield!(inConsCell, :tail, inNewRest)
  return inConsCell
end

""" O(1). A destructive operation changing the \"first\" part of a cons-cell. """
@noinline function listSetFirst(inConsCell::Cons{T}, inNewContent::T)::Cons{T} where {T}
  setfield!(inConsCell, :head, inNewContent)
  return inConsCell
end

""" O(n) """
function listArrayLiteral(lst::List{T})::Vector{T} where {T}
  local N = length(lst)
  local arr::Vector{T} = Vector{T}(undef, N)
  i = 1
  while lst isa Cons
    arr[i] = lst.head
    i += 1
    lst = lst.tail
  end
  return arr
end

"""
```
listGetFirstAsPtr(lst::Cons{T})::Ptr{T}
```
  Dangerous function.
  Gets the first element of the list as a pointer of type T.
  Unless it is nil then we get a NULL pointer
"""
function listGetFirstAsPtr(lst::List{T})::Ptr{T} where {T}
  unsafe_getListHeadAsPtr(lst)
end

"""
Dangerous function.
Gets the first element of the list as a pointer of type T.
Unless it is nil then we get a NULL pointer
"""
function unsafe_getListHeadAsPtr(lst::Cons{T}) where {T}
  Ptr{T}(_value_ptr(lst) + _headOffset(Cons{T}))
end

"""
``` listGetFirstAsPtr(nil)::Ptr{Nothing}```
Returns a null pointer
"""
function unsafe_getListHeadAsPtr(lst::Nil)
  _value_ptr(nil)
end

"""
  Fetches the pointer to the tail of the list.
"""
function unsafe_getListTailAsPtr(lst::Cons{T}) where {T}
  convert(Ptr{Cons{T}}, _value_ptr(lst.tail))
end

"""
In a unsafe way get a pointer to a list.
"""
function unsafe_getListAsPtr(lst::List{T}) where {T}
  unsafe_getListAsPtr(lst, Any)
end

function unsafe_getListAsPtr(lst::Cons{T}, ::Type) where {T}
  Ptr{Cons{T}}(_value_ptr(lst))
end

function unsafe_getListAsPtr(::Nil, ::Type{TYPE}) where {TYPE}
  Ptr{Cons{TYPE}}()
end

export listArrayLiteral
export listGetFirstAsPtr, listReverseInPlace, listReverseInPlaceUnsafe
export listSetFirst, listSetRest

end #Unsafe
