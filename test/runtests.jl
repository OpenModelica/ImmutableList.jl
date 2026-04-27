using ImmutableList
using Test

@testset "Baseline tests" begin

  @test 0 == begin
    Ints = List{Int}
    a::Ints = nil
    length(a)
  end

  @test 3 == begin
    ints::List{Int} = list(1, 2, 3)
    length(ints)
  end

  @test 3 == begin
    length(Cons(1, Cons(2, Cons(3,nil))))
  end

  #= Test cons operator =#
  @test 3 == begin
    length(1 <| 2 <| 3 <| nil)
  end

  #= The empty list is a List =#
  @test nil == list()

  @test 3 == begin
    local lst = nil
    for i in [1,2,3]
      lst = i <| lst
    end
    length(lst)
  end
  @test 3 == begin
    local lst = nil
    for i in [1,2,3]
      lst = i <| lst
    end
  length(lst)
  end
  #Test Concrete type
  @test let
    try
      lst1::List{Int64} = 1 <| nil
      true
    catch E
      println(E)
      false
    end
  end
  #Test generic type 1
  @test let
    try
      lst1::List{Any} = 1 <| nil
      true
    catch E
      println(E)
      false
    end
  end
  #Test generic type 2
  @test let
    try
      lst1::List{Any} = 1 <| nil
      true
    catch E
      println(E)
      false
    end
  end
  #Test generic type 3
  @test let
    try
      lst1::List{Integer} = list(1,2,3)
    true
    catch E
      println(E)
      false
    end
  end
end

@testset "List assignment tests for complex types" begin
abstract type SUPER end
struct SUB <: SUPER
  A
  B
end
struct SUB2 <: SUPER
  C
  D
end

@testset "Test the list construction order" begin

@test let
  try
    lst::List{Any} = list(SUB(1,2), SUB2(3,4), SUB(4,5))

    SUB(1,2) == listGet(lst, 1) && SUB2(3,4) == listGet(lst, 2) && SUB(4,5) == listGet(lst, 3)
  catch E
    println(E)
    false
  end
end

end

@test let
  try
    lst1::List{Any} = list(SUB(1,2), SUB(1,2), SUB(1,2))
    true
  catch E
    println(E)
    false
  end
end

#Test generic assignment for a complex type when returning from a function
@test let
  foo()::List{Any} = list(SUB(1,2), SUB(1,2), SUB(1,2))
  try
    lst1::List{Any} = foo()
    true
  catch E
    prinln(E)
    false
  end
end

#Test supertype assignment for a complex type when returning from a function
@test let
  function bar(lst::List{T})::List{T} where {T <: Any}
    lst
  end
  try
    lst2::List{SUPER} = bar(list(SUB(1,2), SUB(1,2), SUB(1,2)))
    true
  catch E
    println(E)
    false
  end
end

@test let
  try
    x = cons(SUB(1,2), cons(SUB2(3, 4), Cons{SUB2}(SUB2(5, 6),nil)))
    t = convert(List{SUPER},x)
    Cons{SUPER} == typeof(x)
  catch E
    println(E)
    false
  end
end

end

#Test list comprehension
@testset "List comprehension test" begin
  @test length(list(i for i in 1:3)) == 3
  @test length(list(i for i in list())) == 0
  lst = list(i*2 for i in list(1,2,3))
  @test sum(lst) == 12
  #= Test guard statement =#
  lst2 = list(i for i in list(1,2,3) if i == 3)
  @test sum(lst2) == 3
  @test length(lst2) == 1
end

@testset "listAppend type widening" begin
  lst = listAppend(list(1, 2, 3), list(4.0, 5))
  @test eltype(lst) === Real
  @test lst == Cons{Real}(1, Cons{Real}(2, Cons{Real}(3, Cons{Real}(4.0, Cons{Real}(5, Nil())))))
end

@testset "List comprehension test. Using supplied type" begin
  @test length(List{Int}(i for i in list())) == 0
  @test length(List{Float64}(i for i in list())) == 0
  @test length(List{Float16}(i for i in list())) == 0
  lst = List{Int}(i*2 for i in list(1,2,3))
  @test sum(lst) == 12
  #= Test guard statement =#
  lst2 = List{Int}(i for i in list(1,2,3) if i == 3)
  @test listHead(lst2) == 3
  @test length(lst2) == 1
  lst3 = List{Float64}(i for i in list(1.0, 2.0, 3.0) if i == 3.0)
  @test listHead(lst3) == 3.0
  @test length(lst3) == 1
  lst4 = List{Float16}(i for i in list(Float16(1), Float16(2), Float16(3)) if i == Float16(3))
  @test listHead(lst4) == Float16(3)
  @test length(lst4) == 1
end

#=We also need to support https://trac.openmodelica.org/OpenModelica/ticket/2816 =#
@testset "Reduction and list flatten test" begin

  @testset "Flatten test" begin
    lst = list(i for i in 1:10 for j in 1:10)
    @test sum(lst) == 550
    lst = list(i for i in 1:10 for j in 1:10 for k in 1:10)
    @test sum(lst) == 5500
  end
  @testset "Reduction test" begin
    #=
    MM:list(a+b for a in 1:2, b in 3:4); // {{4,5}, {5,6}}
    JL:list(a+b for a in 1:2, b in 3:4); // {{4,5}, {5,6}}
    =#
    lst1 = list(a+b for a in 1:2, b in 3:4)
    @test length(lst1) == 2
    @test listHead(listHead(lst1)) == 4
    #=
    MM:list(a+b threaded for a in 1:2, b in 3:4) = {4, 6}
    JL:list(a+b @threaded for a in 1:2,b in 3:4) = {4, 6}
    =#
    @testset "Threaded Reduction test" begin
      @test list(@do_threaded_for a + b (a,b) (1:2, 3:4)) == list(4,6)
      @test sum(list(@do_threaded_for a + b (a,b) (1:10,1:10))) == 110
      lst = 1 <| list(@do_threaded_for a + b (a,b) (1:2, 3:4))
      @test lst == list(1,4,6)
    end
  end
end

@testset "Eltype and instantiation of composite with subtype tests" begin
  @test Int64 == eltype(list(1,2,3))
  #= Our list is now a union =#
  @test Cons{Int64} == eltype(list(list(1)))

  abstract type AS end
  struct SUBTYPE <: AS
    a
  end
  struct SS
    a::List{AS}
  end
@test begin
  try
    SS(list(SUBTYPE(1), SUBTYPE(2), SUBTYPE(3)))
    true
  catch
    false
  end
end
end

@testset "Testing type conversion for lists of lists" begin
  @test true == begin
    try
      let
        a::List{List{Integer}} = list(list())
        true
      end
    catch
      println("Conversion failure")
      false
    end
  end
  @test true == let
      try
        a::List{List{Integer}} = list(list(1))
        b::List{List{Integer}} = list(list(1,2,3))
        length(a) == length(b)
      catch
        println("Conversion failure")
        false
      end
  end
  abstract type AbsFoo end
  struct Foo <: AbsFoo
    msg::String
  end
  struct FooBar <: AbsFoo
    msg::String
  end
  #= Test to see if conversion to common abstract type works =#
@test true == let
  try
    lst = list(Foo("a"), Foo("a"), Foo("a"), Foo("a"), Foo("a"), FooBar("c"), FooBar("c"))
      eltype(lst) ===  AbsFoo
  catch e
    println("Conversion failure")
    false
  end
end
@test true == let
  try
    lst = list(
      ("a", Foo("a")),
      ("a", Foo("a")),
      ("a", Foo("a")),
      ("b", FooBar("b")),
      ("b", FooBar("b")),
      ("b", FooBar("b")),)
    true
  catch e
    println("Conversion failure")
    false
  end
end

@test true == let
  try
    lst = list(
      ("a", FooBar("a")),
      ("b", FooBar("b")),
      ("a", Foo("a")),
      ("b", FooBar("b")),
      ("b", FooBar("b")),
      ("b", FooBar("b")),)
    true
  catch
    println("Conversion failure")
    false
  end
  end

end

@testset "Unsafe destructive operations" begin
  import ImmutableList.Unsafe

  @test begin
    c = list(10, 20, 30)
    Unsafe.listSetFirst(c, 99)
    collect(c) == [99, 20, 30]
  end

  @test begin
    c = list(10, 20, 30)
    Unsafe.listSetFirst(c.tail, 222)
    collect(c) == [10, 222, 30]
  end

  @test begin
    c = list("a", "b", "c")
    Unsafe.listSetFirst(c, "replaced")
    collect(c) == ["replaced", "b", "c"]
  end

  @test begin
    c = list(1, 2, 3)
    Unsafe.listSetRest(c, nil)
    collect(c) == [1]
  end

  @test begin
    c = list(1, 2, 3)
    Unsafe.listSetRest(c, list(99))
    collect(c) == [1, 99]
  end

  @test begin
    c = list(1, 2)
    Unsafe.listSetRest(c, list(100, 200, 300))
    collect(c) == [1, 100, 200, 300]
  end

  @test begin
    c = list(1, 2, 3, 4, 5)
    r = Unsafe.listReverseInPlaceUnsafe(c)
    collect(r) == [5, 4, 3, 2, 1]
  end

  @test Unsafe.listReverseInPlaceUnsafe(nil) === nil

  @test Unsafe.listArrayLiteral(list(1, 2, 3)) == [1, 2, 3]
  @test Unsafe.listArrayLiteral(list("x", "y")) == ["x", "y"]
  @test Unsafe.listArrayLiteral(nil) isa Vector
end
