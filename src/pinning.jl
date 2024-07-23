"""
$(TYPEDSIGNATURES)
Pin the calling Julia thread to the given CPU-thread.
"""
function pinthread(cpuid::Integer; warn::Bool = first_pin_attempt())
    if warn
        _check_environment()
        _check_slurm()
    end
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
    fetch(@spawnat threadid pinthread(cpuid; kwargs...))
    return
end

"""
    pinthreads(cpuids[; nthreads, force=true, warn=first_pin_attempt(), threadpool=:default])
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

The keyword argument `threadpool` can be used to indicate the pool of threads to be pinned.
Supported values are `:default`, `:interactive`, or `:all`. (Requires Julia >= 1.9.)

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
            return Threads.nthreads(:default) + Threads.nthreads(:interactive)
        else
            return Threads.nthreads(threadpool)
        end
    else
        return Threads.nthreads()
    end
end

function pinthreads(cpuids::AbstractVector{<:Integer};
        warn::Bool = first_pin_attempt(),
        force = true,
        threadpool = :default,
        nthreads = _nthreadsarg(threadpool))
    # TODO: maybe add `periodic` kwarg for PBC as alternative to strict `min` below.
    if force || first_pin_attempt()
        if warn
            _check_environment()
            _check_slurm()
        end
        _check_cpuids(cpuids)
        tids = threadids(threadpool)
        limit = min(length(cpuids), nthreads)
        @debug("pinthreads", limit, nthreads, tids)
        for (i, tid) in pairs(@view(tids[1:limit]))
            pinthread(tid, cpuids[i]; warn = false)
        end
    end
    return
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
        nthreads = Threads.nthreads(), warn = false, kwargs...)
    mask = initial_affinity_mask()
    isnothing(mask) && error("No (or non-unique) external affinity mask set.")
    cpuids = affinitymask2cpuids(mask)
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
    pinthreads(cpuids; nthreads, warn, kwargs...)
    return
end

"""
$(SIGNATURES)
Runs the function `f` with the specified pinning and restores the previous thread affinities
afterwards. Typically to be used in combination with do-syntax.

By default (`soft=false`), before the thread affinities are restored, the Julia
threads will be pinned to the CPU-threads they were running on previously.

**Example**
```julia
julia> getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4

julia> with_pinthreads(:cores) do
           getcpuids()
       end
4-element Vector{Int64}:
 0
 1
 2
 3

julia> getcpuids()
4-element Vector{Int64}:
  7
 75
 63
  4
```
"""
function with_pinthreads(f::F,
        args...;
        threadpool = :default,
        soft = false,
        kwargs...) where {F}
    masks_prior = uv_thread_getaffinity.(threadids(threadpool))
    cpuids_prior = getcpuids()
    pinthreads(args...; threadpool, kwargs...)
    res = f()
    soft || pinthreads(cpuids_prior)
    uv_thread_setaffinity.(threadids(threadpool), masks_prior)
    return res
end

"""
Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads()
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    fill!(cpumask, 1)
    for tid in threadids()
        uv_thread_setaffinity(tid, cpumask)
    end
    return
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
    return
end

function _check_slurm()
    if SLURM.isslurmjob() && !SLURM.hasfullnode()
        @warn("You seem to be running in a SLURM allocation that doesn't cover the entire "*
              "node. Most likely, only a subset of the available CPU-threads will be "*
              "accessible. This might lead to unexpected/wrong pinning results.")
    end
    return
end

function _check_cpuids(cpuids)
    if !all(c -> c in cpuids_all(), cpuids)
        valid_cpuids = cpuids_all()
        problem_cpuids = filter(c -> !(c in valid_cpuids), cpuids)
        throw(ArgumentError("Invalid CPU ID(s) encountered: $(problem_cpuids). See `cpuids_all()` for all " *
                            "valid CPU IDs on the system."))
    end
    return
end

# global "constants"
const FIRST_PIN = Ref{Bool}(true)

first_pin_attempt() = FIRST_PIN[]
function forget_pin_attempts()
    FIRST_PIN[] = true
    return
end

const INITIAL_AFFINITY_MASK = Ref{Union{Nothing, Vector{Cchar}}}(nothing)

initial_affinity_mask() = INITIAL_AFFINITY_MASK[]
function set_initial_affinity_mask(mask::Vector{Cchar})
    INITIAL_AFFINITY_MASK[] = mask
    return
end
function set_initial_affinity_mask()
    masks = [getaffinity(; threadid=id) for id in 1:Threads.nthreads()]
    mask = first(masks)
    if !all(isequal(mask), masks)
        @debug("No unique initial affinity mask.")
        INITIAL_AFFINITY_MASK[] = nothing
    else
        INITIAL_AFFINITY_MASK[] = mask
    end
    return
end
