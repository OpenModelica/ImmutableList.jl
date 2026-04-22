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
 NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler.
"""
@noinline function listSetRest(inConsCell::Cons{T}, inNewRest::Union{Nil, Cons{T}})::Cons{T} where {T}
  GC.@preserve inConsCell inNewRest begin
    slot = Ptr{Ptr{Cvoid}}(_value_ptr(inConsCell) + _tailOffset(Cons{T}))
    unsafe_store!(slot, _value_ptr(inNewRest))
  end
  if inNewRest isa Cons
    _queue_root(inConsCell)
  end
  return inConsCell
end

""" O(1). A destructive operation changing the \"first\" part of a cons-cell. """
@noinline function listSetFirst(inConsCell::Cons{T}, inNewContent::T)::Cons{T} where {T}
  GC.@preserve inConsCell inNewContent begin
    base = _value_ptr(inConsCell) + _headOffset(Cons{T})
    if isbitstype(T)
      unsafe_store!(Ptr{T}(base), inNewContent)
    else
      unsafe_store!(Ptr{Ptr{Cvoid}}(base), _value_ptr(inNewContent))
      _queue_root(inConsCell)
    end
  end
  return inConsCell
end

""" O(n) """
function listArrayLiteral(lst::List{T})::Vector{T} where {T}
  local N = length(lst)
  local arr::Vector{T} = Vector{T}(undef, N)
  i = 1
  while lst !== nil
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
