@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), "```julia" => "```jldoctest mylabel")
end module RectiGrids

export RectiGrid, grid, dimnames, axiskeys, KeyedArray, named_axiskeys, →

using ConstructionBase: constructorof
using AxisKeys


# https://github.com/JuliaObjects/ConstructionBaseExtras.jl/pull/3 and https://github.com/JuliaObjects/ConstructionBaseExtras.jl/pull/4
using StaticArraysCore: SVector
import ConstructionBase
ConstructionBase.constructorof(::Type{SVector}) = SVector
ConstructionBase.constructorof(sa::Type{<:SVector{S,<:Any}}) where {S} = SVector{S}


include("pair.jl")


struct RectiGridArr{KS, T, N, TK <: Tuple, TV <: Tuple} <: AbstractArray{T, N}
    axiskeys::TK
    axisvals::TV
end
const RectiGridArrNdim{N} = RectiGridArr{KS, T, N} where {KS, T}

const RectiGrid = Union{
    RectiGridArr,
    KeyedArray{T, N, <:RectiGridArr} where {T, N},
    KeyedArray{T, N, <:SubArray{T, N, <:RectiGridArr}} where {T, N},
    KeyedArray{T, N, <:AxisKeys.NamedDimsArray{NS, TNS, N, <:RectiGridArr}} where {T, N, NS, TNS},
    KeyedArray{T, N, <:AxisKeys.NamedDimsArray{NS, TNS, N, <:SubArray{T, N, <:RectiGridArr}}} where {T, N, NS, TNS},
}

RectiGridArr{KS, T}(akvals::Tuple) where {KS, T} = RectiGridArr{KS, T}(keyarr.(akvals), valarr.(akvals))
(RectiGridArr{KS, NamedTuple})(akeys, avals) where {KS} = RectiGridArr{KS, NamedTuple{KS, Tuple{eltype.(avals)...}}}(akeys, avals)
(RectiGridArr{KS, Tuple})(akeys, avals) where {KS} = RectiGridArr{KS, Tuple{eltype.(avals)...}}(akeys, avals)
function (RectiGridArr{KS, T})(akeys, avals) where {KS, T}
    # rely on return_type inference:
    ET = Core.Compiler.return_type(constructorof(T), Tuple{map(eltype, avals)...})
    # without relying on inference, but doesn't work for empty grids:
    # ET = constructorof(T)(map(first, avals)...) |> typeof
    ET <: T && ET != Union{} || throw(ArgumentError("Type $T isn't constructible from provided values"))
    RectiGridArr{KS, ET, length(KS), typeof(akeys), typeof(avals)}(akeys, avals)
end

Base.size(a::RectiGridArr) = map(length, a.axisvals)

function Base.getindex(A::RectiGridArrNdim{N}, I_raw::Vararg{<:Any, N}) where {N}
    I = to_indices(A, I_raw)
    is_scalar = I isa Tuple{Vararg{Integer}}
    if is_scalar
        constructorof(eltype(A))(map((ax, i) -> ax[i], A.axisvals, I)...)
    else
        all(i -> !(i isa Integer), I) || throw("Only all-scalar or all-nonscalar indexing is supported")
        RectiGridArr{dimnames(A), eltype(A)}(map((ax, i) -> ax[i], A.axisvals, I))
    end
end

# don't define methods for AxisKeys functions, that's not needed
# these are just simple accessors, to be used in this package only
_dimnames(a::RectiGridArr{KS}) where {KS} = KS
_axiskeys(a::RectiGridArr) = something.(a.axiskeys, a.axisvals)

function AxisKeys.KeyedArray(a::RectiGridArr)
    if isempty(_dimnames(a))
        # XXX: doesn't really matter for zero-dim grid, right?..
        KeyedArray(NamedDimsArray{_dimnames(a)}(a), _axiskeys(a))
    elseif eltype(_dimnames(a)) == Symbol
        KeyedArray(NamedDimsArray{_dimnames(a)}(a), _axiskeys(a))
    else
        @assert eltype(_dimnames(a)) == Int
        KeyedArray(a, _axiskeys(a))
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

@inline grid(::Type{T}; kwargs...) where {T} = RectiGridArr{keys(kwargs), T}(values(values(kwargs))) |> KeyedArray
@inline grid(::Type{T}, args::AbstractVector...) where {T} = RectiGridArr{grid_dimnames(T, args), T}(args) |> KeyedArray
@inline grid(args::AbstractVector...) = grid(Tuple, args...)
@inline grid(; kwargs...) = grid(NamedTuple; kwargs...)
@inline grid(args::Tuple) = grid(Tuple, args...)
@inline grid(args::NamedTuple) = grid(NamedTuple; args...)

@inline function _grid(a::RectiGridArr{KS1}, b::RectiGridArr{KS2}) where {KS1, KS2}
    @assert isempty(intersect(KS1, KS2))
    @assert Base.typename(eltype(a)) == Base.typename(eltype(b))
    RectiGridArr{(_dimnames(a)..., _dimnames(b)...), Base.typename(eltype(a)).wrapper}((a.axiskeys..., b.axiskeys...), (a.axisvals..., b.axisvals...))
end

grid(a::RectiGrid, b::RectiGrid) = _grid(AxisKeys.keyless_unname(a), AxisKeys.keyless_unname(b)) |> KeyedArray


function grid_dimnames(T, args)
    fnames = maybe_fieldnames(T)
    if !isnothing(fnames) && length(fnames) == length(args)
        fnames
    else
        eachindex(args)
    end
end

@generated function maybe_fieldnames(::Type{T}) where {T}
    try
        ns = fieldnames(T)
    catch
        nothing
    end
end

end
