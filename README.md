# ImmutableList

[![Tests](https://github.com/OpenModelica/ImmutableList.jl/actions/workflows/CI.yaml/badge.svg?branch=master)](https://github.com/OpenModelica/ImmutableList.jl/actions/workflows/CI.yaml)
[![OMJL integration](https://github.com/OpenModelica/ImmutableList.jl/actions/workflows/omjl.yml/badge.svg?branch=master)](https://github.com/OpenModelica/ImmutableList.jl/actions/workflows/omjl.yml)

A singly linked immutable list for Julia: MetaModelica's `list`, as used by the OpenModelica
compiler packages ([OMFrontend.jl](https://github.com/OpenModelica/OMFrontend.jl),
[OMBackend.jl](https://github.com/OpenModelica/OMBackend.jl)), with Julia's collection interfaces.

A list is either `nil` (empty) or a `Cons` cell holding a head and the rest of the list. Adding to the
front shares the rest, so `cons` and `tail` are O(1); indexing and `length` walk the list, O(n).

## Use
```julia
using ImmutableList

l = list(3, 1, 2)          # list{Int64}[3, 1, 2]
m = 4 <| l                 # cons: list{Int64}[4, 3, 1, 2], shares l
List([1, 2]), List{Float64}((1, 2)), List(x^2 for x in 1:3)   # from any iterable
collect(l)                 # [3, 1, 2]

first(l), last(l), tail(l) # 3, 2, list{Int64}[1, 2]
h, t... = l                # h = 3, t = tail(l)
l[2], l[end], l[2:end]     # 1, 2, list{Int64}[1, 2] (the tail, no copy)

map(x -> 2x, l)            # list{Int64}[6, 2, 4]
filter(isodd, l)           # list{Int64}[3, 1]
sort(l), reverse(l)        # list{Int64}[1, 2, 3], list{Int64}[2, 1, 3]
vcat(l, list(7))           # list{Int64}[3, 1, 2, 7] (shares the last list)
sum(l), maximum(l), 2 in l, findfirst(==(1), l), foldr(-, l)
list(1, 2) == List([1.0, 2.0])   # true; hash and isequal agree
```

## Julia interfaces
- **Iteration**: `iterate`, `length`, `eltype`, `isempty`, so `collect`, `sum`, `in`, `zip`, `enumerate`,
  `Iterators.*`, `foldl`/`reduce` work. `Iterators.reverse` and `foldr` too.
- **Indexing**, O(i): `l[i]`, `l[a:b]`, `firstindex`, `lastindex`, `keys`, `eachindex`, `pairs`,
  `findfirst`, `findall`. A `BoundsError` outside `1:length(l)`.
- **First, last, rest**: `first(l)`, `last(l)` (the last element, O(n)), `tail(l)` (O(1)),
  `first(l, n)`, `last(l, n)` (shares the cells), `x, rest... = l`. `first`, `last` and `tail` of
  `nil` are `nil`. `tail` of anything else is `Base.tail` (tuples).
- **New collections are lists**: `map`, `filter`, `reverse`, `sort` (with `by`, `lt`, `rev`), `vcat`,
  `empty`. An empty result is `nil`.
- **Equality and hashing** element by element, as for Vectors: `==`, `isequal`, `hash`; lists work as
  `Dict` keys.
- **Construction and conversion**: `List(itr)`, `List{T}(itr)`, `List{T}()`, `collect(l)`,
  `collect(T, l)`; `promote_type(Cons{Int}, Cons{Float64}) == Cons{Float64}`.
- **Printing**: `show` gives `list{T}[a, b]` (elements as in a Vector); `string(l)` keeps the MetaModelica
  format `list{T}[a,b]`.

Loading the package invalidates no compiled code (checked with `jl_debug_method_invalidation`).

## MetaModelica functions
`listHead`, `listRest`, `listGet`, `listLength`, `listMember`, `listAppend`, `listReverse`,
`listDelete`, `listEmpty`, `cons`, `<|`; `sort(l, f)` with MetaModelica's order (`f(a, b)` true means
`a` comes after `b`). `ImmutableList.Unsafe` has the destructive operations (`listSetFirst`,
`listSetRest`, `listReverseInPlaceUnsafe`) for code that needs them.

## Changes in 0.6.0
- `last(l)` is the last element (it was the tail); the tail is `tail(l)` (or `listRest`).
- `map` returns a list (it returned a Vector); `filter`, `vcat`, `reverse`, `first(l, n)` and the rest
  of the interfaces above are new.
- `==`, `isequal` and `hash` compare elements (`==` compared with `===`).
- `eltype(Nil{T}())` is `T`; `promote_rule` on two `Cons` types works (it referred to an undefined name).

## License

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

The BSD 3-Clause text is in [LICENSE.md](LICENSE.md).
