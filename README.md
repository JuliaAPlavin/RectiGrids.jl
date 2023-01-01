# RectiGrids.jl

Simple rectilinear grids in Julia. A grid is effectively a cartesian product of values in each dimension.

Grids are created with the `grid()` function:

```julia
julia> using RectiGrids

julia> G = grid(20:30, [:a, :b, :c])
2-dimensional KeyedArray(...) with keys:
↓   11-element UnitRange{Int64}
→   3-element Vector{Symbol}
And data, 11×3 RectiGrids.RectiGridArr{Base.OneTo(2), Tuple{Int64, Symbol}, 2, Tuple{UnitRange{Int64}, Vector{Symbol}}}:
       (:a)        (:b)        (:c)
 (20)    (20, :a)    (20, :b)    (20, :c)
 (21)    (21, :a)    (21, :b)    (21, :c)
 (22)    (22, :a)    (22, :b)    (22, :c)
 (23)    (23, :a)    (23, :b)    (23, :c)
 (24)    (24, :a)    (24, :b)    (24, :c)
 (25)    (25, :a)    (25, :b)    (25, :c)
 (26)    (26, :a)    (26, :b)    (26, :c)
 (27)    (27, :a)    (27, :b)    (27, :c)
 (28)    (28, :a)    (28, :b)    (28, :c)
 (29)    (29, :a)    (29, :b)    (29, :c)
 (30)    (30, :a)    (30, :b)    (30, :c)

```

Grids are `KeyedArray`s, so they implement the `Base.AbstractArray` interface:

```julia
julia> G isa AbstractArray
true

julia> size(G)
(11, 3)

julia> eltype(G)
Tuple{Int64, Symbol}

julia> G[3, 1]
(22, :a)
```

... and the `KeyedArray` interface:

```julia
julia> dimnames(G)
(:_, :_)

julia> axiskeys(G, 2)
3-element Vector{Symbol}:
 :a
 :b
 :c

julia> G(25, :b)
(25, :b)
```

Each dimension can be named:

```julia
julia> G = grid(x=20:30, y=[:a, :b, :c])
2-dimensional KeyedArray(NamedDimsArray(...)) with keys:
↓   x ∈ 11-element UnitRange{Int64}
→   y ∈ 3-element Vector{Symbol}
And data, 11×3 RectiGrids.RectiGridArr{(:x, :y), NamedTuple{(:x, :y), Tuple{Int64, Symbol}}, 2, Tuple{UnitRange{Int64}, Vector{Symbol}}}:
       (:a)                (:b)                (:c)
 (20)    (x = 20, y = :a)    (x = 20, y = :b)    (x = 20, y = :c)
 (21)    (x = 21, y = :a)    (x = 21, y = :b)    (x = 21, y = :c)
 (22)    (x = 22, y = :a)    (x = 22, y = :b)    (x = 22, y = :c)
 (23)    (x = 23, y = :a)    (x = 23, y = :b)    (x = 23, y = :c)
 (24)    (x = 24, y = :a)    (x = 24, y = :b)    (x = 24, y = :c)
 (25)    (x = 25, y = :a)    (x = 25, y = :b)    (x = 25, y = :c)
 (26)    (x = 26, y = :a)    (x = 26, y = :b)    (x = 26, y = :c)
 (27)    (x = 27, y = :a)    (x = 27, y = :b)    (x = 27, y = :c)
 (28)    (x = 28, y = :a)    (x = 28, y = :b)    (x = 28, y = :c)
 (29)    (x = 29, y = :a)    (x = 29, y = :b)    (x = 29, y = :c)
 (30)    (x = 30, y = :a)    (x = 30, y = :b)    (x = 30, y = :c)

julia> eltype(G)
NamedTuple{(:x, :y), Tuple{Int64, Symbol}}

julia> G[3, 1]
(x = 22, y = :a)

julia> dimnames(G)
(:x, :y)

julia> axiskeys(G, 2)
3-element Vector{Symbol}:
 :a
 :b
 :c

julia> axiskeys(G, :y)
3-element Vector{Symbol}:
 :a
 :b
 :c

julia> G(25, :b)
(x = 25, y = :b)
```
