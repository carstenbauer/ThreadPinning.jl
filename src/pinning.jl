"""
$(TYPEDSIGNATURES)
Pin the calling Julia thread to the given CPU-thread.
"""
function pinthread(cpuid::Integer; warn::Bool = true)
    warn && _check_environment()
    if !(cpuid in cpuids_all())
        throw(ArgumentError("Inavlid CPU ID encountered. See `cpuids_all()` for all " *
                            "valid CPU IDs on the system."))
    end
    FIRST_PIN[] = false
    return uv_thread_setaffinity(cpuid)
end

"""
$(TYPEDSIGNATURES)
Pin a Julia thread to a specific CPU-thread.
"""
function pinthread(threadid::Integer, cpuid::Integer; kwargs...)
    fetch(@tspawnat threadid pinthread(cpuid; kwargs...))
    return nothing
end

"""
    pinthreads(cpuids[; nthreads=Threads.nthreads(), force=true, warn=true])
Pin the first `min(length(cpuids), nthreads)` Julia threads to an explicit or implicit list
of CPU IDs. The latter can be specified in three ways:

1) explicitly (e.g. `0:3` or `[0,12,4]`),
2) by passing one of several predefined symbols (e.g. `:cores` or `:sockets`),
3) by providing a logical specification via helper functions (e.g. `node` and `socket`).

See below for more information.

If `force=false` the `pinthreads` call will only pin threads
if this is the first attempt to pin threads with ThreadPinning.jl. Otherwise it will be a
no-op. This may be particularly useful for packages that merely want to specify a
"default pinning".

The option `warn` toggles general warnings, such as unwanted interference with BLAS thread
settings.

**1) Explicit**

Simply provide an `AbstractVector{<:Integer}` of CPU IDs. The latter are expected to be the
"physical" ids, i.e. as provided by `lscpu`, and thus start at zero!

**2) Predefined Symbols**

* `:cputhreads` or `:compact`: successively pin to all available CPU-threads.
* `:cores`: spread threads across all available cores, only use hyperthreads if necessary.
* `:sockets`: spread threads across sockets (round-robin), only use hyperthreads if
              necessary. Set `compact=true` to get compact pinning within each socket.
* `:numa`: spread threads across NUMA/memory domains (round-robin), only use hyperthreads
           if necessary. Set `compact=true` to get compact pinning within each NUMA/memory
           domain.
* `:random`: pin threads randomly to CPU-threads
* `:current`: pin threads to the CPU-threads they are currently running on
* `:firstn`: pin threads to CPU-threads in "physical" order (as specified by lscpu).
* `:affinitymask`: pin threads to different CPU-threads in accordance with their
                   affinity mask (must be the same for all of them). By default,
                   `hyperthreads_last=true`.

**3) Logical Specification**

The functions [`node`](@ref), [`socket`](@ref), [`numa`](@ref), and [`core`](@ref) can be
used to to specify CPU IDs of/within a certain domain. Moreover, the functions
[`sockets`](@ref) and [`numas`](@ref) can be used to express a round-robin scatter policy
between sockets or NUMA domains, respectively.

*Examples (domains):*
* `pinthreads(socket(1, 1:3))` # pin to the first 3 cores in the first socket
* `pinthreads(socket(1, 1:3; compact=true))` # pin to the first 3 CPU-threads in the first
  socket
* `pinthreads(numa(2, [2,4,6]))` # pin to the second, the fourth, and the sixth cores in
  the second NUMA/memory domain
* `pinthreads(node(ncores():-1:1))` # pin threads to cores in reversing order (starting at
  the end of the node)
* `pinthreads(sockets())` # scatter threads between sockets, cores before hyperthreads

Different domains can be concatenated by providing them in a vector or as separate
arguments to `pinthreads`.

*Examples (concatenation):*

* `pinthreads([socket(1, 1:3), numa(2, 4:6)])`
* `pinthreads(socket(1, 1:3), numa(2, 4:6))`
"""
function pinthreads end

function _nthreadsarg(threadpool)
    @static if VERSION >= v"1.9-"
        if threadpool == :all
            return Threads.maxthreadid()
        else
            return Threads.nthreads(threadpool)
        end
    else
        return Threads.nthreads()
    end
end

function pinthreads(cpuids::AbstractVector{<:Integer};
                    warn::Bool = true,
                    force = true,
                    threadpool = :default,
                    nthreads = _nthreadsarg(threadpool))
    # TODO: maybe add `periodic` kwarg for PBC as alternative to strict `min` below.
    if force || first_pin_attempt()
        warn && _check_environment()
        _check_cpuids(cpuids)
        limit = min(length(cpuids), nthreads)
        @static if VERSION >= v"1.9-"
            if threadpool == :all
                tids = 1:Threads.maxthreadid()
            else
                tids = filter(i -> Threads.threadpool(i) == threadpool,
                              1:Threads.maxthreadid())
            end
        else
            tids = 1:limit
        end
        @debug("pinthreads", limit, nthreads, tids)
        for (i, tid) in pairs(@view(tids[1:limit]))
            pinthread(tid, cpuids[i]; warn = false)
        end
    end
    return nothing
end

function pinthreads(cpuids::AbstractVector{<:Integer};
                    warn::Bool = true, force = true, nthreads = Threads.nthreads())
    # TODO: maybe add `periodic` kwarg for PBC as alternative to strict `min` below.
    if force || first_pin_attempt()
        warn && _check_environment()
        _check_cpuids(cpuids)
        limit = min(length(cpuids), nthreads)
        @threads :static for tid in 1:limit
            pinthread(cpuids[tid]; warn = false)
        end
    end
    return nothing
end

# concatenation
function pinthreads(cpuids_vec::AbstractVector{T};
                    kwargs...) where {T <: AbstractVector{<:Integer}}
    return pinthreads(reduce(vcat, cpuids_vec); kwargs...)
end
function pinthreads(cpuids_args::AbstractVector{<:Integer}...; kwargs...)
    return pinthreads(reduce(vcat, cpuids_args); kwargs...)
end

# convenience symbols
pinthreads(symb::Symbol; kwargs...) = pinthreads(Val(symb); kwargs...)
function pinthreads(::Union{Val{:compact}, Val{:threads}, Val{:cputhreads}}; kwargs...)
    pinthreads(node(; compact = true); kwargs...)
end
function pinthreads(::Union{Val{:cores}}; kwargs...)
    pinthreads(node(; compact = false); kwargs...)
end
function pinthreads(::Val{:sockets}; compact = false, kwargs...)
    pinthreads(sockets(; compact); kwargs...)
end
function pinthreads(::Union{Val{:numa}, Val{:numas}}; compact = false, kwargs...)
    pinthreads(numas(; compact); kwargs...)
end
pinthreads(::Val{:random}; kwargs...) = pinthreads(node(; shuffle = true); kwargs...)
pinthreads(::Val{:firstn}; kwargs...) = pinthreads(cpuids_all(); kwargs...)
pinthreads(::Val{:current}; kwargs...) = pinthreads(getcpuids(); kwargs...)
function pinthreads(::Val{:affinitymask}; hyperthreads_last = true,
                    nthreads = Threads.nthreads(), kwargs...)
    masks = get_affinity_mask.(1:nthreads)
    mask = first(masks)
    if !all(isequal(mask), masks)
        error("Julia threads have different affinity masks.")
    end
    cpuids = get_cpuids_from_affinity_mask(mask)
    if length(cpuids) < nthreads
        error("More Julia threads than CPU-threads specified by affinity mask.")
    end
    if hyperthreads_last
        # sort cpuids such that hyperthreads come last
        by_func(c) = (c, ishyperthread(c))
        lt_func(x, y) =
            if x[2] != y[2]
                return x[2] < y[2] # non-hyperthreads first
            else
                return x[1] < y[1] # lower cpuid first
            end
        sort!(cpuids; lt = lt_func, by = by_func)
    end
    pinthreads(cpuids; nthreads, kwargs...)
    return nothing
end

"""
Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads()
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    fill!(cpumask, 1)
    for tid in 1:nthreads()
        uv_thread_setaffinity(tid, cpumask)
    end
    return nothing
end

"""
$(SIGNATURES)
Unpins the given Julia thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread(threadid::Integer)
    if !(1 ≤ threadid ≤ Threads.nthreads())
        throw(ArgumentError("Invalid thread id (out of bounds)."))
    end
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    fill!(cpumask, 1)
    return uv_thread_setaffinity(threadid, cpumask)
end

# Potentially throw warnings if the environment is such that thread pinning might not work.
function _check_environment()
    if Base.Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can "*
              "spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` "*
              "to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end

function _check_cpuids(cpuids)
    if !all(c -> c in cpuids_all(), cpuids)
        throw(ArgumentError("Inavlid CPU ID encountered. See `cpuids_all()` for all " *
                            "valid CPU IDs on the system."))
    end
    return nothing
end

# global "constants"
const FIRST_PIN = Ref{Bool}(true)

first_pin_attempt() = FIRST_PIN[]
function forget_pin_attempts()
    FIRST_PIN[] = true
    return nothing
end
