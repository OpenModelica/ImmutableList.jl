
""" Throws ImmutableListFailure """
function listFail()
  throw(ImmutableListException("listFail"))
end


"""
  Append with both lists nil is nil
"""
function listAppend(lst1::Nil{T}, lst2::Nil) where {T}
  nil
end

"""
  Append when lst1 is a cons and lst 2 is nil is lst1
"""
function listAppend(lst1::Cons{T}, lst2::Nil) where {T}
  lst1
end

"""
  Append when lst2 is a cons cell and lst 1 is nil is lst1
"""
function listAppend(lst1::Nil, lst2::Cons{T}) where {T}
  lst2
end

""" O(length(lst1)), O(1) if either list is empty.. needs improvment """
function listAppend(lst1::Cons{T}, lst2::Cons{T}) where {T}
  for c in listReverse(lst1)
    lst2 = cons(c, lst2)
  end
  lst2
end

function listLength(lst::List{T})::Int where {T}
  length(lst)
end

""" O(n) """
function listMember(element::T, lst::List{T})::Bool where {T}
  for e in lst
    if e == element
      return true
    end
  end
  false
end

function listGet(lst::Nil{T}, index #= one-based index =#::Int)::T where {T}
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
function listRest(lst::Nil{T}) where {T}
  listFail()
end

""" O(1) """
function listRest(lst::Cons{T}) where {T}
  return lst.tail
end


"""
  The head of the nil element is undefined.
"""
function listHead(lst::Nil{T})::T where {T}
  listFail()
end


""" Returns the head of a list. 
Time complexity: O(1) """
function listHead(lst::Cons{T})::T where {T}
  lst.head
end

""" O(index) """
function listDelete(inLst::List{A}, index #= one-based index =#::Int)::List{A} where {A}
  local outLst::List{A} = nil
  local i = 1
  for el in inLst:-1:1
    if index != i
      outLst = cons(el, outLst)
    end
    i = i + 1
  end
  outLst
end

Base.string(lst::Nil) = let
  "{}"
end

Base.string(lst::Cons) = let
  res = "{"
  for e in lst
    res *= string(e) * "<-" 
  end
  res *= "nil}"
end

"""
A list with a cons cell is not empty
"""
function listEmpty(lst::Cons{T})::Bool where {T}
  false
end

""" A list consisting of a nil element is empty """
function listEmpty(lst::Nil{T})::Bool where {T}
  true
end

export listAppend
export listReverse
export listReverseInPlace
export listLength
export listMember
export listGet
export listRest
export listHead
export listDelete
export listEmpty
export ImmutableListException
