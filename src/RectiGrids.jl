@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest mylabel")
end module RectiGrids

export RectiGrid, grid, dimnames, axiskeys, KeyedArray, named_axiskeys

using AxisKeys


struct RectiGrid{KS, T, N, TV <: Tuple} <: AbstractArray{T, N}
    axiskeys::TV
end
const RectiGridNdim{N} = RectiGrid{KS, T, N} where {KS, T}

(RectiGrid{KS, NamedTuple})(axiskeys) where {KS} = RectiGrid{KS, NamedTuple{KS, Tuple{eltype.(axiskeys)...}}}(axiskeys)
(RectiGrid{KS, Tuple})(axiskeys) where {KS} = RectiGrid{KS, Tuple{eltype.(axiskeys)...}}(axiskeys)
function (RectiGrid{KS, T})(axiskeys) where {KS, T}
    first_elt = T(map(first, axiskeys))
    RectiGrid{KS, typeof(first_elt), length(KS), typeof(axiskeys)}(axiskeys)
end

Base.size(a::RectiGrid) = map(length, a.axiskeys)

Base.getindex(A::RectiGridNdim{N}, I::Vararg{Int, N}) where {N} = eltype(A)(map((ax, i) -> ax[i], A.axiskeys, I))
Base.getindex(A::RectiGridNdim{N}, I::Vararg{Union{AbstractVector, Colon}, N}) where {N} = RectiGrid{dimnames(A), eltype(A)}(map((ax, i) -> ax[i], A.axiskeys, I))
function Base.getindex(A::RectiGrid; Ikw...)
    if isempty(Ikw)
        # called rg[]: return the only element in a 1-element grid
        @assert length(A) == 1
        eltype(A)(Tuple{}())
    else
        # call like rg[a=..., b=..., ...]: resolve dimension names
        I = AxisKeys.NamedDims.order_named_inds(Val(dimnames(A)); Ikw...)
        return A[I...]
    end
end

function Base.in(x, A::RectiGrid)
    x isa eltype(A) || return false
    all(map((xx, ax) -> xx ∈ ax, x, A.axiskeys))
end

function (A::RectiGrid)(args...)
    @assert length(args) == ndims(A)
    inds_raw = map(AxisKeys.findindex, args, axiskeys(A))
    inds = Base.to_indices(A, inds_raw)
    return A[inds...]
end

function (A::RectiGrid)(; kwargs...)
    issubset(keys(kwargs), dimnames(A)) || error("some keywords not in list of names!")
    args = map(s -> Base.sym_in(s, keys(kwargs)) ? getfield(values(kwargs), s) : Colon(), dimnames(A))
    A(args...)
end

AxisKeys.dimnames(a::RectiGrid{KS}) where {KS} = KS
AxisKeys.dimnames(a::RectiGrid, d::Int) = dimnames(a)[d]

AxisKeys.axiskeys(a::RectiGrid) = a.axiskeys
AxisKeys.axiskeys(a::RectiGrid, d) = a.axiskeys[AxisKeys.dim(a, d)]

AxisKeys.dim(a::RectiGrid, d) = AxisKeys.dim(dimnames(a), d)

function AxisKeys.KeyedArray(a::RectiGrid)
    if eltype(dimnames(a)) == Symbol
        KeyedArray(NamedDimsArray{dimnames(a)}(a), axiskeys(a))
    else
        @assert eltype(dimnames(a)) == Int
        KeyedArray(a, axiskeys(a))
    end
end

"""
```
grid([T], xs, ys, ...) -> RectiGrid
grid([T], x=xs, y=ys, ...) -> RectiGrid
```

Create a `RectiGrid` object representing a rectilinear grid. Implements `AbstractArray` and `KeyedArray` interfaces.

Pass positional arguments `xs, ys, ...` for a grid with unnamed dimensions, or keyword arguments `x=xs, y=ys, ...` for named dimensions.

Type `T` can be `Tuple`, or a type with a `T(::Tuple)` constructor (e.g. `SVector`), or `NamedTuple` when dimensions are named.
"""
function grid end

grid(::Type{NamedTuple}; kwargs...) = RectiGrid{keys(kwargs), NamedTuple}(values(values(kwargs)))
grid(::Type{Tuple}; kwargs...) = RectiGrid{keys(kwargs), Tuple}(values(values(kwargs)))
grid(::Type{Tuple}, args::AbstractVector...) = RectiGrid{eachindex(args), Tuple}(args)
grid(::Type{T}; kwargs...) where {T<:AbstractVector} = RectiGrid{keys(kwargs), T}(values(values(kwargs)))
grid(::Type{T}, args::AbstractVector...) where {T<:AbstractVector} = RectiGrid{eachindex(args), T}(args)
grid(args::AbstractVector...) = grid(Tuple, args...)
grid(; kwargs...) = grid(NamedTuple; kwargs...)

function grid(a::RectiGrid{KS1}, b::RectiGrid{KS2}) where {KS1, KS2}
    @assert isempty(intersect(KS1, KS2))
    @assert Base.typename(eltype(a)) == Base.typename(eltype(b))
    RectiGrid{(dimnames(a)..., dimnames(b)...), Base.typename(eltype(a)).wrapper}((a.axiskeys..., b.axiskeys...))
end

end
