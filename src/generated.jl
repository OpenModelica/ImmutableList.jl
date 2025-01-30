#=
Experiment with generated functions
=#

#= List of two elements =#
"""
Internal helper function do not call outside.
"""
function _warnIfNil(els)
  local warn = false
  for e in els
    if e === Nil{Any}
      warn = true
    end
  end
  return warn
end

function _typeJoinElems(a::T0, b::T1) where {T0, T1}
  S = typejoin(a, b)
  if T0 !== Any && T1 === Any
    @warn "Unstable Immutable List created with the following types\n $(T0), $(T1), $(S)"
  end
  return S
end

"""
  Internal function
"""
function _typeJoinElems(AT::Type, BT::Type, els::Tuple)
  # println("typeJoinElems1")
  # println(AT)
  # println(BT)
  local S = typejoin(AT, BT)
  local warn = false
  for e in els
    S = typejoin(AT, BT, e, S)
    if e === Nil{Any}
      S = Any
      warn = true
      break
    end
  end
  if warn && AT !== Any && BT !== Any
    @warn "Unstable Immutable List created with the following types\n $(AT), $(BT), $(S)"
  end
  return S
end

function list(a::A, b::B) where {A, B}
  if @generated
    #println("1 Calling actual1")
    local S = _typeJoinElems(a, b)
    return :(Cons{$S}(a, Cons{$S}(b, nil)))
  else
    #println("1 Calling actual2")
    local S::Type = _typeJoinElems(A, B)
    return Cons{S}(a, Cons{S}(b, nil))
  end
end

#= Several elements =#
function list(a::A, b::B, els...) where {A, B}
  if @generated
    local N = length(els)
    #println("Calling actual1")
    local S = _typeJoinElems(A, B, els)
    local lstEx = :(nil)
    for i in N:-1:1
      lstEx = :(Cons{$(S)}(els[$(i)], $(lstEx)))
    end
    lstEx = :(Cons{$(S)}(a, Cons{$(S)}(b, $(lstEx))))
    return lstEx
  else
    #println("Calling actual2")
    local N = length(els)
    local S = _typeJoinElems(typeof(a), typeof(b), els)
    local lst = nil
    for i in N:-1:1
      lst = Cons{S}(els[i], lst)
    end
    lst = Cons{S}(a, Cons{S}(b, lst))
    return lst
  end
end
