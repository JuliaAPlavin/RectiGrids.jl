# RectiGrids.jl

✨ **Flexible rectilinear grids in Julia**

RectiGrids.jl provides a clean efficient way to create and work with rectilinear grids - essentially cartesian products of values across multiple dimensions. Perfect for parameter sweeps, coordinate systems, and any scenario where you need structured multi-dimensional data.

## 🚀 Quick Start

```julia
julia> using RectiGrids

# Create a simple 2D grid
julia> G = grid(1:3, [:x, :y])
2-dimensional KeyedArray(...)
       (:x)        (:y)
 (1)    (1, :x)     (1, :y)
 (2)    (2, :x)     (2, :y)
 (3)    (3, :x)     (3, :y)

# Access elements like any array
julia> G[2, 1]
(2, :x)

# Or use axiskeys-based indexing
julia> G(2, :y)
(2, :y)
```

## ✨ Key Features

- **Seamless Array Interface**: Grids are `AbstractArray`s and `KeyedArray`s
- **Named Dimensions**: Give meaningful names to your grid dimensions
- **Flexible Element Types**: Support for tuples, named tuples, custom structs, and more
- **Efficient Indexing**: Both integer and coordinate-based access

## 📚 Core Concepts

RectiGrids work by creating cartesian products of values. Think of them as "meshgrids" that store the coordinate combinations rather than just providing indexing.

### Basic Usage

Create grids with positional arguments for unnamed dimensions:

```julia
julia> grid(1:3, [:a, :b])
2-dimensional KeyedArray(...)
       (:a)        (:b)
 (1)    (1, :a)     (1, :b)
 (2)    (2, :a)     (2, :b)
 (3)    (3, :a)     (3, :b)
```

### Array Interface Compatibility

Grids implement the complete `AbstractArray` interface:

```julia
julia> G = grid(20:25, [:x, :y, :z])

julia> G isa AbstractArray
true

julia> size(G)
(6, 3)

julia> eltype(G)
Tuple{Int64, Symbol}

julia> G[3, 1]
(22, :a)
```

### KeyedArray Features

Access grid properties and use coordinate-based indexing:

```julia
julia> dimnames(G)
(:_, :_)

julia> axiskeys(G, 2)  # Get keys for dimension 2
3-element Vector{Symbol}:
 :x
 :y
 :z

julia> G(22, :y)  # Coordinate-based access
(22, :y)
```

## 🏷️ Named Dimensions

Give your dimensions meaningful names for cleaner, more readable code:

```julia
julia> G = grid(x=1:3, y=[:a, :b])
2-dimensional KeyedArray(NamedDimsArray(...)) with keys:
↓   x ∈ 3-element UnitRange{Int64}
→   y ∈ 2-element Vector{Symbol}
And data, 3×2 RectiGrids.RectiGridArr{(:x, :y), NamedTuple{(:x, :y), Tuple{Int64, Symbol}}, 2, ...}:
       (:a)                (:b)
 (1)    (x = 1, y = :a)     (x = 1, y = :b)
 (2)    (x = 2, y = :a)     (x = 2, y = :b)
 (3)    (x = 3, y = :a)     (x = 3, y = :b)

julia> eltype(G)
NamedTuple{(:x, :y), Tuple{Int64, Symbol}}

julia> G[2, 1]
(x = 2, y = :a)

julia> dimnames(G)
(:x, :y)

julia> axiskeys(G, :y)  # Access by dimension name
2-element Vector{Symbol}:
 :a
 :b

julia> G(x=2, y=:b)  # Named coordinate access
(x = 2, y = :b)
```

## 🔧 Advanced Features

### Custom Element Types

Create grids with any constructible type:

```julia
# StaticArrays for high-performance applications
julia> using StaticArrays

julia> grid(SVector, 1:3, [:a, :b])
2-dimensional KeyedArray(...) with keys:
↓   3-element UnitRange{Int64}
→   2-element Vector{Symbol}
And data, 3×2 RectiGrids.RectiGridArr{...}:
      (:a)       (:b)
 (1)    [1, :a]    [1, :b]
 (2)    [2, :a]    [2, :b]
 (3)    [3, :a]    [3, :b]

# Define custom struct
julia> struct Point3D
           x::Float64
           y::Float64
           z::Float64
       end

julia> grid(Point3D, 0:2:10, [-1, 0, 1], [0.0, 0.5, 1.0])
3-dimensional KeyedArray(NamedDimsArray(...)) with keys:
↓   x ∈ 6-element StepRange{Int64,...}
→   y ∈ 3-element Vector{Int64}
◪   z ∈ 3-element Vector{Float64}
And data, 6×3×3 RectiGrids.RectiGridArr{(:x, :y, :z), Point3D, 3, ...}:
[:, :, 1] =
       (-1)                          (0)                         (1)
  (0)      Point3D(0.0, -1.0, 0.0)      Point3D(0.0, 0.0, 0.0)      Point3D(0.0, 1.0, 0.0)
  (2)      Point3D(2.0, -1.0, 0.0)      Point3D(2.0, 0.0, 0.0)      Point3D(2.0, 1.0, 0.0)
  (4)      Point3D(4.0, -1.0, 0.0)      Point3D(4.0, 0.0, 0.0)      Point3D(4.0, 1.0, 0.0)
  (6)      Point3D(6.0, -1.0, 0.0)      Point3D(6.0, 0.0, 0.0)      Point3D(6.0, 1.0, 0.0)
  (8)      Point3D(8.0, -1.0, 0.0)      Point3D(8.0, 0.0, 0.0)      Point3D(8.0, 1.0, 0.0)
 (10)      Point3D(10.0, -1.0, 0.0)     Point3D(10.0, 0.0, 0.0)     Point3D(10.0, 1.0, 0.0)

<...>
```

### Key-Value Pairs for Non-Sequential Data

The `→` operator lets you separate **axis keys** (used for indexing) from **element values** (stored in the grid):

```julia
julia> grid(id=[:alice, :bob, :charlie], score=[1→85, 2→92, 3→78])
2-dimensional KeyedArray(NamedDimsArray(...)) with keys:
↓   id ∈ 3-element Vector{Symbol}
→   score ∈ 3-element Vector{Int64}  # Keys: [1, 2, 3] for indexing
And data, 3×3 RectiGrids.RectiGridArr{(:id, :score), @NamedTuple{id::Symbol, score::Int64}, 2, ...}:
              (1)                             (2)                             (3)
  (:alice)       (id = :alice, score = 85)       (id = :alice, score = 92)       (id = :alice, score = 78)
  (:bob)         (id = :bob, score = 85)         (id = :bob, score = 92)         (id = :bob, score = 78)
  (:charlie)     (id = :charlie, score = 85)     (id = :charlie, score = 92)     (id = :charlie, score = 78)

# Indexing uses the keys [1, 2, 3], but elements contain the values [85, 92, 78]
julia> g(id=:alice, score=2)  # Key=2 maps to value=92
(id = :alice, score = 92)

julia> axiskeys(g, :score)  # Shows the indexing keys
3-element Vector{Int64}:
 1
 2
 3
```

**What's happening**: 
- **Axis keys** are `[1, 2, 3]` (left side of `→`) - used for indexing like `g(score=2)`
- **Element values** are `[85, 92, 78]` (right side of `→`) - stored in the actual grid elements
- Each person gets paired with each score value, creating all combinations

### Combining Grids

Combine multiple grids to create higher-dimensional parameter spaces:

```julia
julia> spatial = grid(x=1:3, y=1:2)
julia> temporal = grid(t=0:0.1:1)
julia> spacetime = grid(spatial, temporal)  # 3×2×11 grid
julia> spacetime[1, 1, 5]
(x = 1, y = 1, t = 0.4)
```

## 🎯 Common Use Cases

### Parameter Sweeps

```julia
# hyperparameter grid
hyperparams = grid(
    learning_rate=[0.001, 0.01, 0.1],
    batch_size=[32, 64, 128],
    dropout=[0.1, 0.2, 0.3]
)

map(hyperparams) do params
    train_model(params.learning_rate, params.batch_size, params.dropout)
end
```

### Coordinate Systems

```julia
# 2D spatial grid for physics simulation
space = grid(x=-5:0.1:5, y=-5:0.1:5)

# Apply function to each coordinate
temperature_field = map(p -> exp(-(p.x^2 + p.y^2)), space)
```

### Data Analysis Scenarios

```julia
# Multi-factor experimental design
experiment = grid(
    treatment=[:control, :drug_a, :drug_b],
    dose=[1, 5, 10],
    time=[1, 24, 48]  # hours
)

# Each element represents a unique experimental condition
map(experiment) do condition
    run_experiment(condition.treatment, condition.dose, condition.time)
end
```

## 📖 API Reference

### Core Functions

- `grid([T], args...)` - Create grid with positional arguments (unnamed dimensions)
- `grid([T]; kwargs...)` - Create grid with keyword arguments (named dimensions) 
- `grid(grid1, grid2)` - Combine two grids into higher dimensions

### Supported Element Types

- `Tuple` (default for positional args)
- `NamedTuple` (default for keyword args)
- `SVector` and other StaticArrays
- Any custom struct with appropriate constructor

### Array Interface

RectiGrids implement the complete `AbstractArray` interface:
- Indexing: `g[i, j]`, `g[1:3, :]`
- Properties: `size(g)`, `length(g)`, `eltype(g)`, `ndims(g)`
- Iteration: `for item in g`
- Broadcasting: `map(f, g)`, `g .+ 1`

### KeyedArray Interface

Enhanced indexing and metadata:
- `dimnames(g)` - Get dimension names
- `axiskeys(g, dim)` - Get keys for a dimension
- `g(1, :a)` - Coordinate-based access
- `g(x=1, y=:a)` - Named coordinate access
