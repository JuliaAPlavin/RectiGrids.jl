module RectiGrids

export grid, dimnames, axiskeys, KeyedArray, named_axiskeys

using AxisKeys


struct Grid{KS, T, N, TV <: Tuple} <: AbstractArray{T, N}
    axiskeys::TV
end

(Grid{KS, NamedTuple})(axiskeys) where {KS} = Grid{KS, NamedTuple{KS, Tuple{eltype.(axiskeys)...}}}(axiskeys)
(Grid{KS, Tuple})(axiskeys) where {KS} = Grid{KS, Tuple{eltype.(axiskeys)...}}(axiskeys)
function (Grid{KS, T})(axiskeys) where {KS, T}
    first_elt = T(map(first, axiskeys))
    Grid{KS, typeof(first_elt), length(KS), typeof(axiskeys)}(axiskeys)
end

Base.size(a::Grid) = map(length, a.axiskeys)

Base.getindex(A::Grid, I::Integer) = A[CartesianIndices(A)[I]]
Base.getindex(A::Grid, I::Integer...) = eltype(A)(map((ax, i) -> ax[i], A.axiskeys, I))
Base.getindex(A::Grid, I::Union{AbstractVector, Colon}...) = Grid{dimnames(A), eltype(A)}(map((ax, i) -> ax[i], A.axiskeys, I))
Base.getindex(A::Grid, I::Union{Integer, AbstractVector, Colon}...) = throw("Mixed vector-integer indexing not supported yet")
function Base.getindex(A::Grid; Ikw...)
    I = AxisKeys.NamedDims.order_named_inds(Val(dimnames(A)); Ikw...)
    return A[I...]
end

function Base.in(x, A::Grid)
    x isa eltype(A) || return false
    all(map((xx, ax) -> xx ∈ ax, x, A.axiskeys))
end

function (A::Grid)(args...)
    @assert length(args) == ndims(A)
    inds_raw = map(AxisKeys.findindex, args, axiskeys(A))
    inds = Base.to_indices(A, inds_raw)
    return A[inds...]
end

function (A::Grid)(; kwargs...)
    issubset(keys(kwargs), dimnames(A)) || error("some keywords not in list of names!")
    args = map(s -> Base.sym_in(s, keys(kwargs)) ? getfield(values(kwargs), s) : Colon(), dimnames(A))
    A(args...)
end

AxisKeys.dimnames(a::Grid{KS}) where {KS} = KS
AxisKeys.dimnames(a::Grid, d::Int) = dimnames(a)[d]

AxisKeys.axiskeys(a::Grid) = a.axiskeys
AxisKeys.axiskeys(a::Grid, d) = a.axiskeys[AxisKeys.dim(a, d)]

AxisKeys.dim(a::Grid, d) = AxisKeys.dim(dimnames(a), d)

function AxisKeys.KeyedArray(a::Grid)
    if eltype(dimnames(a)) == Symbol
        KeyedArray(NamedDimsArray{dimnames(a)}(a), axiskeys(a))
    else
        @assert eltype(dimnames(a)) == Int
        KeyedArray(a, axiskeys(a))
    end
end

"""
```
grid([T], xs, ys, ...) -> Grid
grid([T], x=xs, y=ys, ...) -> Grid
```

Create a `Grid` object representing a rectilinear grid. Implements `AbstractArray` and `KeyedArray` interfaces.

Pass positional arguments `xs, ys, ...` for a grid with unnamed dimensions, or keyword arguments `x=xs, y=ys, ...` for named dimensions.

Type `T` can be `Tuple`, or a type with a `T(::Tuple)` constructor (e.g. `SVector`), or `NamedTuple` when dimensions are named.
"""
function grid end

grid(::Type{NamedTuple}; kwargs...) = Grid{keys(kwargs), NamedTuple}(values(values(kwargs)))
grid(::Type{Tuple}; kwargs...) = Grid{keys(kwargs), Tuple}(values(values(kwargs)))
grid(::Type{Tuple}, args::AbstractVector...) = Grid{eachindex(args), Tuple}(args)
grid(::Type{T}; kwargs...) where {T<:AbstractVector} = Grid{keys(kwargs), T}(values(values(kwargs)))
grid(::Type{T}, args::AbstractVector...) where {T<:AbstractVector} = Grid{eachindex(args), T}(args)
grid(args::AbstractVector...) = grid(Tuple, args...)
grid(; kwargs...) = grid(NamedTuple; kwargs...)

function grid(a::Grid{KS1}, b::Grid{KS2}) where {KS1, KS2}
    @assert isempty(intersect(KS1, KS2))
    @assert Base.typename(eltype(a)) == Base.typename(eltype(b))
    Grid{(dimnames(a)..., dimnames(b)...), Base.typename(eltype(a)).wrapper}((a.axiskeys..., b.axiskeys...))
end

end
