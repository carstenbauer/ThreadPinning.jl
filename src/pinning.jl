"""
    pinthread(cpuid::Integer; warn::Bool = true)

Pin the calling Julia thread to the CPU with id `cpuid`.
"""
function pinthread(cpuid::Integer; warn::Bool = true)
    if warn
        (minimum(cpuids_all()) ≤ cpuid ≤ maximum(cpuids_all())) ||
            throw(ArgumentError("cpuid is out of bounds ($(minimum(cpuids_all())) ≤ cpuid ≤ $(maximum(cpuids_all())))."))
        _check_environment()
    end
    return uv_thread_setaffinity(cpuid)
end

"""
    pinthread(threadid::Integer, cpuid::Integer; kwargs...)

Pin the given Julia thread (`threadid`) to the CPU with ID `cpuid`.
"""
function pinthread(threadid::Integer, cpuid::Integer; kwargs...)
    fetch(@tspawnat threadid pinthread(cpuid; kwargs...))
    return nothing
end

"""
    pinthreads(cpuids::AbstractVector{<:Integer}[; warn])
Pins the first `1:length(cpuids)` Julia threads to the CPUs with ids `cpuids`.
Note that `length(cpuids)` may not be larger than `Threads.nthreads()`.

For more information see `pinthread`.
"""
function pinthreads(cpuids::AbstractVector{<:Integer}; warn::Bool = true)
    warn && _check_environment()
    ncpuids = length(cpuids)
    ncpuids ≤ nthreads() ||
        throw(ArgumentError("length(cpuids) must be ≤ Threads.nthreads()"))
    (minimum(cpuids) ≥ minimum(cpuids_all()) && maximum(cpuids) ≤ maximum(cpuids_all())) ||
        throw(ArgumentError("All cpuids must be ≤ $(maximum(cpuids_all)) and ≥ $(minimum(cpuids_all()))."))
    @threads :static for tid in 1:ncpuids
        pinthread(cpuids[tid]; warn = false)
    end
    return nothing
end

"""
    pinthreads(strategy::Symbol[; nthreads, warn, kwargs...])
Pin the first `1:nthreads` Julia threads according to the given pinning `strategy`.
Per default, `nthreads == Threads.nthreads()`

Allowed strategies:
* `:compact`: pins to the first `nthreads` cpu threads while trying to avoid using hyperthreads (i.e. moving to next socket before using hyperthreads). If `hyperthreads=true`, hyperthreads will be used before moving to the next socket, if necessary.
* `:scatter` or `:spread` or `sockets`: pins to all available sockets in an alternating / round robin fashion.
* `:numa`: pins to all available NUMA nodes in an alternating / round robin fashion.
* `:random` or `:rand`: pins threads to random cpu threads (ensures that no cpu thread is double occupied). By default (`hyperthreads=false`), hyperthreads will be ignored.
* `:firstn`: pins to the cpuids `0:nthreads-1`
"""
function pinthreads(strategy::Symbol; nthreads = Threads.nthreads(), warn::Bool = true,
                    kwargs...)
    maybe_gather_sysinfo()
    warn && _check_environment()
    if strategy == :compact
        return _pin_compact(nthreads; kwargs...)
    elseif strategy in (:scatter, :spread, :sockets)
        return _pin_scatter(nthreads; kwargs...)
    elseif strategy == :numa
        return _pin_numa(nthreads; kwargs...)
    elseif strategy in (:rand, :random)
        return _pin_random(nthreads; kwargs...)
    elseif strategy == :firstn
        return _pin_firstn(nthreads)
    else
        throw(ArgumentError("Unknown pinning strategy."))
    end
end

_pin_firstn(nthreads) = pinthreads(0:(nthreads - 1); warn = false)
function _pin_random(nthreads; hyperthreads = false)
    if !hyperthreads
        cpuids = shuffle!(filter(!ishyperthread, cpuids_all()))
    else
        cpuids = shuffle(cpuids_all())
    end
    return pinthreads(@view(cpuids[1:nthreads]); warn = false)
end
function _pin_compact(nthreads; hyperthreads = false)
    if !hyperthreads
        cpuids_noht = filter(!ishyperthread, cpuids_all())
        cpuids_ht = filter(ishyperthread, cpuids_all())
        cpuids = @views vcat(cpuids_noht, cpuids_ht)[1:nthreads]
    else
        cpuids = @views cpuids_all()[1:nthreads]
    end
    return pinthreads(cpuids; warn = false)
end
function _pin_scatter(nthreads)
    cpuids = interweave(cpuids_per_socket()...)
    pinthreads(@view cpuids[1:nthreads]; warn = false)
    return nothing
end
function _pin_numa(nthreads)
    cpuids = interweave(cpuids_per_numa()...)
    pinthreads(@view cpuids[1:nthreads]; warn = false)
    return nothing
end

# Potentially throw warnings if the environment is such that thread pinning might not work.
function _check_environment()
    if Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end
