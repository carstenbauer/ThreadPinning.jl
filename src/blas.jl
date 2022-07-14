"""
Check if MKL library `libmkl_rt.so` is available in `Libdl.dllist()`
(as is the case when loading [MKL.jl](https://github.com/JuliaLinearAlgebra/MKL.jl) or [MKL_jll.jl](https://github.com/JuliaBinaryWrappers/MKL_jll.jl)).
"""
mkl_is_loaded() = any(endswith(lib, "libmkl_rt.$(Libdl.dlext)") for lib in Libdl.dllist())

"Try to find `libmkl_rt.so` in `Libdl.dllist()`. Returns `nothing` if it can't be found."
function find_mkl()
    for lib in Libdl.dllist()
        if endswith(lib, "libmkl_rt.$(Libdl.dlext)")
            return lib
        end
    end
    return nothing
end

"""
    mkl_get_dynamic()
Wrapper around the MKL function [`mkl_get_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-fortran/top/support-functions/threading-control/mkl-get-dynamic.html).
"""
mkl_get_dynamic() = @ccall find_mkl().mkl_get_dynamic()::Cint

"""
    mkl_set_dynamic(flag::Integer)
Wrapper around the MKL function [`mkl_set_dynamic`](https://www.intel.com/content/www/us/en/develop/documentation/onemkl-developer-reference-c/top/support-functions/threading-control/mkl-set-dynamic.html).
"""
mkl_set_dynamic(flag::Integer) = @ccall find_mkl().MKL_Set_Dynamic(flag::Cint)::Cvoid

"Returns the name of the loaded BLAS library (the first, if multiple are loaded)"
BLAS_lib() = basename(first(BLAS.get_config().loaded_libs).libname)

"""
Sets thread affinity for OpenBLAS threads. `thread_idx` is in [0, openblas_get_num_threads()-1].
"""
function _openblas_setaffinity(thread_idx, cpusetsize, cpu_set::Ref{Ccpu_set_t})
    @ccall "libopenblas64_.so".openblas_setaffinity(thread_idx::Cint, cpusetsize::Csize_t, cpu_set::Ptr{Ccpu_set_t})::Cint
end

"""
The input `mask` should be either of the following:
* a `BitArray` indicating the mask directly
* a vector of cpuids (the mask will be constructed automatically)
"""
function openblas_set_affinity_mask(threadid, mask; juliathread=1)
    cpuset = Ccpu_set_t(mask)
    cpuset_ref = Ref{Ccpu_set_t}(cpuset)
    ret = fetch(@tspawnat juliathread _openblas_setaffinity(threadid-1, sizeof(cpuset), cpuset_ref))
    if ret != 0
        @warn "_openblas_setaffinity call returned a non-zero value (indicating failure)"
    end
    return nothing
end
function openblas_pinthread(threadid, cpuid; juliathread=1)
    openblas_set_affinity_mask(threadid, [cpuid]; juliathread)
end
function openblas_pinthreads(threadids, cpuids; juliathread=1)
    @assert length(threadids) == length(cpuids)
    for i in eachindex(threadids, cpuids)
        openblas_pinthread(threadids[i], cpuids[i]; juliathread)
    end
    return nothing
end
openblas_pinthreads(cpuids; juliathread=1) = openblas_pinthreads(1:length(cpuids), cpuids; juliathread)

function openblas_pinthreads(strategy::Symbol; nthreads=nblasthreads(), juliathread=1, kwargs...)
    maybe_gather_sysinfo()
    cpuids = if strategy == :compact
        _strategy_compact(; kwargs...)
    elseif strategy in (:scatter, :spread, :sockets)
        _strategy_scatter(; kwargs...)
    elseif strategy == :numa
        _strategy_numa(; kwargs...)
    elseif strategy in (:rand, :random)
        _strategy_random(; kwargs...)
    elseif strategy == :firstn
        _strategy_firstn(nthreads)
    else
        throw(ArgumentError("Unknown pinning strategy."))
    end
    openblas_pinthreads(@view(cpuids[1:nthreads]); juliathread)
end

nblasthreads() = BLAS.get_num_threads()
