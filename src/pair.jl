struct KeyValPair{K, V}
    k::K
    v::V
end

→(k, v) = KeyValPair(k, v)

keyarr(X) = nothing  # iterables
keyarr(X::AbstractArray) = nothing
keyarr(X::AbstractArray{<:KeyValPair}) = map(x -> x.k, X)
valarr(X) = vec(collect(X))  # iterables
valarr(X::AbstractArray) = X
valarr(X::AbstractArray{<:KeyValPair}) = map(x -> x.v, X)
