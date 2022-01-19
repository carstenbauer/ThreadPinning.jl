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
1:4, 5:8, 9:12 == [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
"""
function interweave(arrays::AbstractVector{T}...) where {T}
    # check input args
    narrays = length(arrays)
    narrays > 0 || throw(ArgumentError("No input arguments provided."))
    len = length(first(arrays))
    for a in arrays
        length(a) == len || throw(ArgumentError("Only same length inputs supported."))
    end
    # interweave
    res = zeros(T, len * narrays)
    c = 1
    for i in eachindex(first(arrays))
        for a in arrays
            @inbounds res[c] = a[i]
            c += 1
        end
    end
    return res
end

"""
Check if MKL library \"libmkl_rt.so\" is available in `Libdl.dllist()`
(as is the case when loading MKL.jl or MKL_jll.jl).
"""
mkl_is_loaded() = any(endswith(lib, "libmkl_rt.$(Libdl.dlext)") for lib in Libdl.dllist())

"Try to find \"libmkl_rt.so\" in `Libdl.dllist()`. Returns `nothing` if it can't be found."
function find_mkl()
    for lib in Libdl.dllist()
        if endswith(lib, "libmkl_rt.$(Libdl.dlext)")
            return lib
        end
    end
    return nothing
end

"Call the MKL function `mkl_get_dynamic`."
mkl_get_dynamic() = @ccall find_mkl().mkl_get_dynamic()::Cint

"Call the MKL function `mkl_set_dynamic`."
mkl_set_dynamic(flag::Integer) = @ccall find_mkl().MKL_Set_Dynamic(flag::Cint)::Cvoid

"Potentially throw warnings if the environment is such that thread pinning might not work."
function _check_environment()
    if Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end