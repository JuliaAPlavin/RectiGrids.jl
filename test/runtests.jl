using Test
using AxisKeys
using LazyGrids

@testset begin
	mp = grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	@test isconcretetype(typeof(mp))
	@test isconcretetype(eltype(mp))
	@test @inferred(size(mp)) == (100, 4)
	@test @inferred(axes(mp)) == (1:100, 1:4)
	@test @inferred(length(mp)) == 400
	@test @inferred(ndims(mp)) == 2
	@test @inferred(mp[1, 2]) == (a=1, b=:y)
end

@testset begin	
	mp = grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	@test mp[:, :] == mp
	@test mp[1:3, 1:2] isa Grid
	@test all(mp[1:3, 1:2] .== [(a = 1, b = :x) (a = 1, b = :y); (a = 2, b = :x) (a = 2, b = :y); (a = 3, b = :x) (a = 3, b = :y)])
	@test all(mp[1:3, [1, 2]] .== [(a = 1, b = :x) (a = 1, b = :y); (a = 2, b = :x) (a = 2, b = :y); (a = 3, b = :x) (a = 3, b = :y)])
	@test_broken mp[1:3, 1]

	@test mp[a=5, b=2] == (a=5, b=:y)
	@test mp[a=:, b=:] == mp
	@test mp(5, :z) == (a=5, b=:z)
	@test mp(a=5, b=:z) == (a=5, b=:z)
	@test mp(a=:, b=:) == mp
	@test mp(a=1:5, b=[:x, :z]) isa Grid
	@test all(mp(a=3:5, b=[:x, :z]) .== [(a = 3, b = :x) (a = 3, b = :z); (a = 4, b = :x) (a = 4, b = :z); (a = 5, b = :x) (a = 5, b = :z)])
end

@testset begin
	mp = grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	@test map(identity, mp) isa Array{<:NamedTuple, 2}
	@test size(map(identity, mp)) == size(mp)
	@test map(identity, mp)[3, 4] == mp[3, 4]
end

@testset begin
	mp = grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	ka = @inferred(KeyedArray(mp))
	@test @inferred(ka(a=5, b=:z)) == (a=5, b=:z)
	@test dimnames(ka) == @inferred(dimnames(mp)) == (:a, :b)
	@test dimnames(ka, 2) == dimnames(mp, 2) == :b
	@test axiskeys(ka) == @inferred(axiskeys(mp)) == (1:100, [:x, :y, :z, :w])
	@test axiskeys(ka, 1) == axiskeys(mp, 1) == 1:100
	@test axiskeys(ka, :a) == axiskeys(mp, :a) == 1:100
	@test AxisKeys.dim(ka, :a) == @inferred(AxisKeys.dim(mp, :a)) == 1
	@test named_axiskeys(mp) == named_axiskeys(ka) == (a=1:100, b=[:x, :y, :z, :w])
	@test AxisKeys.NamedDims.named_size(mp) == AxisKeys.NamedDims.named_size(ka) == (a=100, b=4)
end

@testset begin
	mp = grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	@test_throws AssertionError grid(mp, mp)
	
	mp2 = grid(NamedTuple, c=1:5, d=[10, 20])
	mp12 = grid(mp, mp2)
	@test @inferred(size(mp12)) == (100, 4, 5, 2)
	@test @inferred(axes(mp12)) == (1:100, 1:4, 1:5, 1:2)
	@test @inferred(length(mp12)) == 4000
	@test @inferred(mp12[5, 2, 4, 1]) == (a=5, b=:y, c=4, d=10)
	@test @inferred(first(mp12)) == (a=1, b=:x, c=1, d=10)
	
	mp21 = grid(mp2, mp)
	@test @inferred(size(mp21)) == (5, 2, 100, 4)
	@test @inferred(axes(mp21)) == (1:5, 1:2, 1:100, 1:4)
	@test @inferred(length(mp21)) == 4000
	@test @inferred(mp21[4, 1, 5, 2]) == (c=4, d=10, a=5, b=:y)
	@test @inferred(first(mp21)) == (c=1, d=10, a=1, b=:x)
end

@testset begin
	mpt = grid(Tuple, a=1:100, b=[:x, :y, :z, :w])
	@test isconcretetype(typeof(mpt))
	@test isconcretetype(eltype(mpt))
	@test @inferred(size(mpt)) == (100, 4)
	@test @inferred(axes(mpt)) == (1:100, 1:4)
	@test @inferred(length(mpt)) == 400
	@test @inferred(ndims(mpt)) == 2
	@test @inferred(mpt[1, 2]) == (1, :y)
	
	@test_throws AssertionError grid(grid(NamedTuple, c=1:5, d=[10, 20]), mpt)
	@test_throws AssertionError grid(mpt, mpt)
	
	mpt2 = grid(Tuple, c=[2, 3], d=[1])
	mpt12 = grid(mpt, mpt2)
	@test isconcretetype(typeof(mpt12))
	@test isconcretetype(eltype(mpt12))
	@test @inferred(size(mpt12)) == (100, 4, 2, 1)
	@test @inferred(axes(mpt12)) == (1:100, 1:4, 1:2, 1:1)
	@test @inferred(length(mpt12)) == 800
	@test @inferred(ndims(mpt12)) == 4
	@test @inferred(mpt12[1, 2, 2, 1]) == (1, :y, 3, 1)

	KeyedArray(mpt)
end

@testset begin
	mptn = grid(Tuple, 1:100, [:x, :y, :z, :w])
	@test isconcretetype(typeof(mptn))
	@test isconcretetype(eltype(mptn))
	@test @inferred(size(mptn)) == (100, 4)
	@test @inferred(axes(mptn)) == (1:100, 1:4)
	@test @inferred(length(mptn)) == 400
	@test @inferred(ndims(mptn)) == 2
	@test @inferred(mptn[1, 2]) == (1, :y)
	
	@test_throws AssertionError grid(grid(NamedTuple, c=1:5, d=[10, 20]), mptn)
	@test_throws AssertionError grid(mptn, mptn)

	KeyedArray(mptn)
end

@testset begin
	@test grid(a=1:100, b=[:x, :y, :z, :w]) == grid(NamedTuple, a=1:100, b=[:x, :y, :z, :w])
	@test grid(1:100, [:x, :y, :z, :w]) == grid(Tuple, 1:100, [:x, :y, :z, :w])
end
