using Test
using StaticArrays
using StableRNGs
using RectiGrids


@testset "array functions" begin
    mp = @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test mp isa RectiGrid
    @test isconcretetype(eltype(mp))
    @test @inferred(size(mp)) == (100, 4)
    @test @inferred(axes(mp)) == (1:100, 1:4)
    @test @inferred(length(mp)) == 400
    @test @inferred(ndims(mp)) == 2
    @test @inferred(mp[1, 2]) == (a=1, b=:y)
    @test @inferred(mp(a=10, b=:w)) == (a=10, b=:w)

    mp1 = @inferred grid(NamedTuple, a=1:100)
    @test mp1 isa RectiGrid
    @test isconcretetype(eltype(mp1))
    @test @inferred(size(mp1)) == (100,)
    @test @inferred(axes(mp1)) == (1:100,)
    @test @inferred(length(mp1)) == 100
    @test @inferred(ndims(mp1)) == 1
    @test @inferred(mp1[3]) == (a=3,)
    @test @inferred(mp1(a=3)) == (a=3,)

    mp2 = @inferred grid(NamedTuple, a=[:x → "XXX", :y → "YYY"])
    @test mp2 isa RectiGrid
    @test isconcretetype(eltype(mp2))
    @test @inferred(length(mp2)) == 2
    @test @inferred(mp2[1]) == (a="XXX",)
    @test @inferred(mp2(a=:y)) == (a="YYY",)
end

@testset "zero-dim grid" begin
    mp = @inferred grid(NamedTuple)
    @test mp isa RectiGrid
    @test isconcretetype(eltype(mp))
    @test @inferred(size(mp)) == ()
    @test @inferred(axes(mp)) == ()
    @test @inferred(length(mp)) == 1
    @test @inferred(ndims(mp)) == 0
    @test_broken mp[] == (;)
    @test @inferred(mp[1]) == (;)

    mp = @inferred grid(Tuple)
    @test mp isa RectiGrid
    @test isconcretetype(eltype(mp))
    @test @inferred(size(mp)) == ()
    @test @inferred(axes(mp)) == ()
    @test @inferred(length(mp)) == 1
    @test @inferred(ndims(mp)) == 0
    @test_broken mp[] == ()
    @test @inferred(mp[1]) == ()
end

@testset "empty grid" begin
    mp = @inferred grid(NamedTuple, a=1:0)
    @test mp isa RectiGrid
    @test isconcretetype(eltype(mp))
    @test @inferred(size(mp)) == (0,)
    @test @inferred(axes(mp)) == (1:0,)
    @test @inferred(length(mp)) == 0
    @test @inferred(ndims(mp)) == 1
    @test_throws BoundsError mp[1]

    mp = @inferred grid(Tuple, a=1:0)
    @test mp isa RectiGrid
    @test isconcretetype(eltype(mp))
    @test @inferred(size(mp)) == (0,)
    @test @inferred(axes(mp)) == (1:0,)
    @test @inferred(length(mp)) == 0
    @test @inferred(ndims(mp)) == 1
    @test_throws BoundsError mp[1]
end

@testset "access grid" begin
    mp = @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test mp[:, :] == mp
    @test mp[1:3, 1:2] isa RectiGrid
    @test all(mp[1:3, 1:2] .== [(a = 1, b = :x) (a = 1, b = :y); (a = 2, b = :x) (a = 2, b = :y); (a = 3, b = :x) (a = 3, b = :y)])
    @test all(mp[1:3, [1, 2]] .== [(a = 1, b = :x) (a = 1, b = :y); (a = 2, b = :x) (a = 2, b = :y); (a = 3, b = :x) (a = 3, b = :y)])
    @test_broken mp[1:3, 1]

    @test mp[a=5, b=2] == (a=5, b=:y)
    @test mp[a=:, b=:] == mp
    @test mp(5, :z) == (a=5, b=:z)
    @test mp(a=5, b=:z) == (a=5, b=:z)
    @test mp(a=:, b=:) == mp
    @test mp(a=1:5, b=[:x, :z]) isa RectiGrid
    @test all(mp(a=3:5, b=[:x, :z]) .== [(a = 3, b = :x) (a = 3, b = :z); (a = 4, b = :x) (a = 4, b = :z); (a = 5, b = :x) (a = 5, b = :z)])

    @test @inferred(mp[123]) == (a = 23, b = :y)
end

@testset "map" begin
    mp = @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test map(identity, mp) isa KeyedArray{<:NamedTuple, 2}
    @test size(map(identity, mp)) == size(mp)
    @test map(identity, mp)[3, 4] == mp[3, 4]
end

@testset "AxisKeys functions" begin
    ka = @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test @inferred(KeyedArray, ka(a=5, b=:z)) == (a=5, b=:z)
    @test dimnames(ka) == @inferred(dimnames(ka)) == (:a, :b)
    @test dimnames(ka, 2) == dimnames(ka, 2) == :b
    @test axiskeys(ka) == @inferred(axiskeys(ka)) == (1:100, [:x, :y, :z, :w])
    @test axiskeys(ka, 1) == axiskeys(ka, 1) == 1:100
    @test axiskeys(ka, :a) == axiskeys(ka, :a) == 1:100
    @test named_axiskeys(ka) == named_axiskeys(ka) == (a=1:100, b=[:x, :y, :z, :w])
end

@testset "combine grids" begin
    mp = @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test_throws AssertionError grid(mp, mp)

    mp2 = @inferred grid(NamedTuple, c=1:5, d=[10, 20])
    mp12 = @inferred grid(mp, mp2)
    @test @inferred(size(mp12)) == (100, 4, 5, 2)
    @test @inferred(axes(mp12)) == (1:100, 1:4, 1:5, 1:2)
    @test @inferred(length(mp12)) == 4000
    @test @inferred(mp12[5, 2, 4, 1]) == (a=5, b=:y, c=4, d=10)
    @test @inferred(first(mp12)) == (a=1, b=:x, c=1, d=10)

    mp21 = @inferred grid(mp2, mp)
    @test @inferred(size(mp21)) == (5, 2, 100, 4)
    @test @inferred(axes(mp21)) == (1:5, 1:2, 1:100, 1:4)
    @test @inferred(length(mp21)) == 4000
    @test @inferred(mp21[4, 1, 5, 2]) == (c=4, d=10, a=5, b=:y)
    @test @inferred(first(mp21)) == (c=1, d=10, a=1, b=:x)
end

@testset "Tuple grid" begin
    mpt = @inferred grid(Tuple, a=1:100, b=[:x, :y, :z, :w])
    @test mpt isa RectiGrid
    @test isconcretetype(eltype(mpt))
    @test @inferred(size(mpt)) == (100, 4)
    @test @inferred(axes(mpt)) == (1:100, 1:4)
    @test @inferred(length(mpt)) == 400
    @test @inferred(ndims(mpt)) == 2
    @test @inferred(mpt[1, 2]) == (1, :y)

    @test_throws AssertionError grid(grid(NamedTuple, c=1:5, d=[10, 20]), mpt)
    @test_throws AssertionError grid(mpt, mpt)

    mpt2 = @inferred grid(Tuple, c=[2, 3], d=[1])
    mpt12 = @inferred grid(mpt, mpt2)
    @test mpt12 isa RectiGrid
    @test isconcretetype(eltype(mpt12))
    @test @inferred(size(mpt12)) == (100, 4, 2, 1)
    @test @inferred(axes(mpt12)) == (1:100, 1:4, 1:2, 1:1)
    @test @inferred(length(mpt12)) == 800
    @test @inferred(ndims(mpt12)) == 4
    @test @inferred(mpt12[1, 2, 2, 1]) == (1, :y, 3, 1)

    @test @inferred(mpt[123]) == (23, :y)
end

@testset "Tuple unnamed grid" begin
    mptn = @inferred grid(Tuple, 1:100, [:x, :y, :z, :w])
    @test mptn isa RectiGrid
    @test isconcretetype(eltype(mptn))
    @test @inferred(size(mptn)) == (100, 4)
    @test @inferred(axes(mptn)) == (1:100, 1:4)
    @test @inferred(length(mptn)) == 400
    @test @inferred(ndims(mptn)) == 2
    @test @inferred(mptn[1, 2]) == (1, :y)

    @test_throws AssertionError grid(grid(NamedTuple, c=1:5, d=[10, 20]), mptn)
    @test_throws AssertionError grid(mptn, mptn)
end

@testset "SVector grid" begin
    mpt = @inferred grid(SVector, a=1:100, b=5:10)
    @test mpt isa RectiGrid
    @test isconcretetype(eltype(mpt))
    @test @inferred(mpt[2, 3]) === SVector(2, 7)
end

struct S{T}
    a::T
    b::T
end

@testset "custom struct" begin
    g = @inferred grid(S, 1:3, [5, 10])
    @test g isa RectiGrid
    @test isconcretetype(eltype(g))
    @test @inferred(g[1, 2]) == S(1, 10)

    g = @inferred grid(S, a=1:3, b=[5, 10])
    @test g isa RectiGrid
    @test isconcretetype(eltype(g))
    @test @inferred(g[1, 2]) == S(1, 10)
end

@testset "default types" begin
    @test @inferred (grid(a=1:100, b=[:x, :y, :z, :w])) == @inferred grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
    @test @inferred(grid(1:100, [:x, :y, :z, :w])) == @inferred grid(Tuple, 1:100, [:x, :y, :z, :w])
end

@testset "all dims as a single arg" begin
    @test grid((a=1:5, b=[:x, :y])) == grid(a=1:5, b=[:x, :y])
    @test grid((1:5, [:x, :y])) == grid(1:5, [:x, :y])
end

@testset "rand" begin
    gt = grid(1:100, [:x, :y, :z, :w])
    gnt = grid(a=1:100, b=[:x, :y, :z, :w])
    @test @inferred(rand(gt)) ∈ gt
    @test @inferred(rand(gt)) ∉ gnt
    @test @inferred(rand(gnt)) ∈ gnt
    @test @inferred(rand(gnt)) ∉ gt
    @test @inferred(rand(StableRNG(123), gt)) == (44, :x)
    @test length(rand(gt, 5)) == 5
    @test rand(StableRNG(123), gt, 10) == [(44, :x), (35, :w), (52, :w), (78, :w), (4, :x), (82, :x), (81, :y), (48, :x), (14, :z), (70, :w)]
end


using Documenter
doctest(RectiGrids; manual=false)


import Aqua
import CompatHelperLocal as CHL
@testset begin
    CHL.@check()
    Aqua.test_ambiguities(RectiGrids, recursive=false)
    Aqua.test_unbound_args(RectiGrids)
    Aqua.test_undefined_exports(RectiGrids)
    Aqua.test_stale_deps(RectiGrids)
end
