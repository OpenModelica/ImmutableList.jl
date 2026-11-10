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

const ILE = ImmutableListException("listFail")
""" Throws ImmutableListFailure """
function listFail()
  throw(ILE)
end


"""
  Append with both lists nil is nil
```
listAppend(lst1::Nil, lst2::Nil)
```
"""
function listAppend(lst1::Nil, lst2::Nil)
  nil
end

"""
  Appending when lst1 is a cons and lst2 is nil is lst1
```
listAppend(lst1::Cons{T}, lst2::Nil) where {T}
```
"""
function listAppend(lst1::Cons{T}, lst2::Nil) where {T}
  lst1
end

"""
  Append when lst2 is a cons cell and lst1 is nil is lst2
```
listAppend(lst1::Nil, lst2::Cons{T}) where {T}
```
"""
function listAppend(lst1::Nil, lst2::Cons{T}) where {T}
  lst2
end

"""
```
listAppend(lst1::Cons{T}, lst2::Cons{T}) where {T}
```

O(length(lst1)), O(1) if either list is empty..

Example:

```
julia> listAppend(list(1,2,3), list(4,5,6))
julia> list{Int64}[1,2,3,4,5,6]
julia> listAppend(list(1,2), list())
julia> list{Int64}[1,2]
```

TODO:
Optimize me:)
"""
function listAppend(lst1::Cons{T}, lst2::Cons{T}) where {T}
  local rev = listReverse(lst1)
  if rev isa Cons{T}
    for c in rev
      lst2 = Cons{T}(c, lst2)
    end
    return lst2
  end
  # heterogeneous chain: rev is already reversed, cons back in order
  local out::List = lst2
  for c in rev
    out = _cons(c, out)
  end
  out
end

function listAppend(lst1::Cons{A}, lst2::Cons{B}) where {A, B}
  _listAppend(lst1, lst2)
end

function listLength(lst::List{T})::Int where {T}
  length(lst)
end

""" O(n). The element may be a different subtype than the list's element type
(MetaModelica lists are covariant). """
function listMember(element, lst::List)::Bool
  for e in lst
    if e == element
      return true
    end
  end
  false
end

function listGet(lst::Nil, index #= one-based index =#::Int)
  listFail()
end

""" O(index) """
function listGet(lst::Cons{T}, index #= one-based index =#::Int)::T where {T}
  if index < 1
    listFail()
  end
  if index == 1
    return listHead(lst)
  end
  local cntr::Int = 0
  for i in lst
    cntr += 1
    if index == cntr
      return i
    end
  end
end

"""
  listRest for nil is not defined.
  Returns an error.
"""
function listRest(lst::Nil)
  listFail()
end

""" O(1) """
function listRest(lst::Cons{T}) where {T}
  return lst.tail
end


"""
  The head of the nil element is undefined.
"""
function listHead(lst::Nil)
  listFail()
end

""" Returns the head of a list.
Time complexity: O(1) """
function listHead(lst::Cons{T})::T where {T}
  lst.head
end

""" O(index) """
function listDelete(inLst::List{A},
                    index #= one-based index =#::Int)::List{A} where {A}
  local outLst::List{A} = nil
  local i = 1
  for el in inLst
    if index != i
      outLst = cons(el, outLst)
    end
    i += 1
  end
  listReverse(outLst)
end

Base.string(lst::Nil) = let
  "{}"
end


Base.string(lst::Cons{T}) where {T}= let
  local res = "list{$(T)}["
  local N = length(lst)
  for (i,e) in enumerate(lst)
    if i != N
      res *= string(e) * ","
    else
      res *= string(e)
    end
  end
  res *= "]"
end

"""
A list with a cons cell is not empty
"""
function listEmpty(lst::Cons{T})::Bool where {T}
  false
end

""" A list consisting of a nil element is empty """
function listEmpty(lst::Nil)::Bool
  true
end

"""
    first(lst::List)

The first element (the head), in O(1). `first(nil)` is `nil`.
"""
Base.first(lst::Cons) = lst.head
Base.first(lst::Nil) = lst

"""
    last(::Nil)

`nil`: `first`, `last` and `tail` of an empty list are the empty list. `last(lst::Cons)` (the last
element) is in interface.jl.
"""
Base.last(lst::Nil) = lst

export listAppend
export listReverse
# No `export listReverseInPlace`: it is defined only in Unsafe, so exporting it here
# published a binding with no value into every module that uses ImmutableList.
export listLength
export listMember
export listGet
export listRest
export listHead
export listDelete
export listEmpty
export ImmutableListException
