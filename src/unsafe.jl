"""
Dangerous/experimental operations...
"""
module Unsafe

using ..ListDef

""" Not possible unless we write a C list impl for Julia """
function listReverseInPlace(inList::List{T})::List{T} where {T}
  listReverse(inList)
end

function listReverseInPlace2(inList::Nil{T}) where {T}
  return nil#MetaModelica.listReverse(inList)
end

"""
 Unsafe implementation of list reverse in place.
 Instead of creating new cons cells we swap pointers...
"""
function listReverseInPlace2(lst::Cons{T})::Cons{T} where {T}
  local prev::Cons{T} = Cons{T}(lst.head, nil)
  local originalPtr::Ptr{Nothing} = unsafe_pointer_from_objref(lst)
  lst = lst.tail::Cons{T}
  local oldCdr::Cons{T} = lst
  #= Declare an unsafe pointer to the list =#
  GC.@preserve while !isa(lst.tail, Nil)
    local oldCdrPtr::Ptr{Cons{T}} = unsafe_getListAsPtr(lst.tail::Cons{T})::Ptr{Cons{T}}
    oldCdr = unsafe_load(oldCdrPtr)
    #= Mutate the tail =#
    listSetRest(lst::Cons{T}, prev::Cons{T})
    #= ################ =#
    prev = lst::Cons{T}
    lst = oldCdr::Cons{T}
  end
  prev = Cons{T}(lst.head, prev)
  unsafe_store!(Ptr{Cons{T}}(originalPtr), prev)
  lst::Cons{T} = unsafe_load(Ptr{Cons{T}}(originalPtr))
end


# """
# O(1). A destructive operation changing the \"first\" part of a cons-cell.
# TODO: Not implemented
# """
# function listSetFirst(inConsCell::Cons{A}, inNewContent::A) where {A} #= A non-empty list =#
#   firstPtr::Ptr{A} = unsafe_getListAsPtr(inConsCell)
#   #local newHead = Cons{T}(inNewContent, inConsCell.tail)
#   # unsafe_store!(firstPtr, inNewContent)
# end

"""
 O(1). A destructive operation changing the rest part of a cons-cell
 NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler.
"""
@noinline function listSetRest(inConsCell::Cons{T}, inNewRest::Cons{T})::Cons{T} where {T} #= A non-empty list =#
  #=
  If the supplied tail is nil.
  then make a new cons cell as we can not seem to able to allocate to the memory location of the nil node.
  (Potential TODO)
  =#
  if inConsCell.tail === nil
    GC.@preserve begin
      local lstPtr::Ptr{Cons{T}} = unsafe_getListAsPtr(inConsCell)
      local val = inConsCell.head::T
      inConsCell = Cons{T}(inConsCell.head, inNewRest)
      unsafe_store!(lstPtr, inConsCell)
    end
    return inConsCell
  end
  GC.@preserve begin
    newTailPtr::Ptr{Cons{T}} =  unsafe_getListAsPtr(inNewRest)
    inConsCellTailPtr::Ptr{Cons{T}} = unsafe_getListAsPtr(inConsCell.tail)
    unsafe_store!(inConsCellTailPtr, unsafe_load(newTailPtr))
  end
  return inConsCell
end

"""
  We create one cons cell when the tail we are setting is a nil...
"""
function listSetRest(inConsCell::Cons{A}, inNewRest::Nil) where {A} #= A non-empty list =#
  GC.@preserve begin
    local lstPtr::Ptr{Cons{A}} = unsafe_getListAsPtr(inConsCell)
    local val = inConsCell.head
    unsafe_store!(lstPtr, Cons{A}(inConsCell.head, inNewRest))
  end
  return inConsCell
end

""" O(1). A destructive operation changing the \"first\" part of a cons-cell. """
function listSetFirst(inConsCell::Cons{A}, inNewContent::A) where {A} #= A non-empty list =#
  GC.@preserve begin
    headPtr = listGetFirstAsPtr(inConsCell)
    unsafe_store!(headPtr, inNewContent)
  end
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
function unsafe_getListHeadAsPtr(lst::Cons{T}) where{T}
  convert(Ptr{T}, unsafe_pointer_from_objref(lst.head))
end

"""
``` listGetFirstAsPtr(nil)::Ptr{Nothing}```
Returns a null pointer
"""
function unsafe_getListHeadAsPtr(lst::Nil)
  unsafe_pointer_from_objref(nil)
end

"""
  Fetches the pointer to the tail of the list
```
unsafe_listGetTailAsPtr{lst::List{T}}::Ptr{Cons{T}}
```
"""
function unsafe_getListTailAsPtr(lst::List{T}) where {T}
  if lst.tail === nil
    return unsafe_pointer_from_objref(nil)
  else
    convert(Ptr{Cons{T}}, unsafe_pointer_from_objref(lst.tail))
  end
end

"""
In a unsafe way get a pointer to a list.
"""
function unsafe_getListAsPtr(lst::List{T}) where {T}
  unsafe_getListAsPtr(lst::List{T}, Any)
end

function unsafe_getListAsPtr(lst::List{T}, TYPE) where {T}
  if lst === nil
    ptrToNil::Ptr{Nil{Any}} = unsafe_pointer_from_objref(nil)
    return Ptr{Cons{TYPE}}() #ptrToNil
  else
    Ptr{Cons{T}}(unsafe_pointer_from_objref(lst))::Ptr{Cons{T}}
  end
end

"""
  Unsafe function to get pointers from immutable struct.
  Use with !care!
"""
function unsafe_pointer_from_objref(@nospecialize(x))
  ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
end

export listArrayLiteral
export listGetFirstAsPtr,listReverseInPlace,listReverseInPlace2
export listSetFirst,listSetRest
end #Unsafe
