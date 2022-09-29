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
        throw(ArgumentError("All cpuids must be ≤ $(maximum(cpuids_all())) and ≥ $(minimum(cpuids_all()))."))
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
    warn && _check_environment()
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
    pinthreads(@view(cpuids[1:nthreads]); warn = false)
end

_strategy_firstn(nthreads) = return 0:(nthreads-1)
function _strategy_random(; hyperthreads = false)
    if !hyperthreads
        cpuids = shuffle!(filter(!ishyperthread, cpuids_all()))
    else
        cpuids = shuffle(cpuids_all())
    end
    return cpuids
end
function _strategy_compact(; hyperthreads = false)
    if !hyperthreads
        cpuids_noht = filter(!ishyperthread, cpuids_all())
        cpuids_ht = filter(ishyperthread, cpuids_all())
        cpuids = vcat(cpuids_noht, cpuids_ht)
    else
        cpuids = cpuids_all()
    end
    return cpuids
end
function _strategy_scatter()
    cpuids = interweave(cpuids_per_socket()...)
    return cpuids
end
function _strategy_numa()
    cpuids = interweave(cpuids_per_numa()...)
    return cpuids
end

# Potentially throw warnings if the environment is such that thread pinning might not work.
function _check_environment()
    if Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end
