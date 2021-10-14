"""
Calls the function `fn` on all Julia threads
and returns the results obtained on each thread
as a ordered `Vector{Any}`.

Example:
```
julia> Pinning.callonthreads(getcpuid)
8-element Vector{Any}:
  3
  4
  5
  8
  2
 10
  6
  9

julia> pinthreads(1:Threads.nthreads())

julia> Pinning.callonthreads(getcpuid)
8-element Vector{Any}:
 1
 2
 3
 4
 5
 6
 7
 8
```
"""
function callonthreads(fn)
    nt = nthreads()
    res = Vector{Any}(undef, nt)
    @threads :static for tid in 1:nt
        res[tid] = fn()
    end
    return res
end

"""
[1,2,3,4], [5,6,7,8] -> [1,5,2,6,3,7,4,8]
"""
function interweave(arrays::AbstractVector{T}...) where T
    # interweaving the arrays (i.e. in alternating fashion)
    lengths = length.(arrays)
    length(unique(lengths)) == 1 || throw(ArgumentError("Only same length inputs supported."))
    narrays = length(arrays)
    nelements = sum(lengths)
    res = zeros(T, nelements)
    for (i, elements) in enumerate(arrays)
        res[i:narrays:end] .= elements
    end
    return res
end