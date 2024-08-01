##
##
## -------------- API --------------
##
##

"""
    pinthread(cpuid::Integer; threadid = Threads.threadid())

Pin the a Julia thread to the given CPU-thread.
"""
function pinthread end

"""
    pinthreads(cpuids;
        nthreads   = nothing,
        force      = true,
        warn       = is_first_pin_attempt(),
        threadpool = :default
    )
Pin Julia threads to an explicit or implicit list of CPU IDs. The latter can be specified
in three ways:

1) by passing one of several predefined symbols (e.g. `pinthreads(:cores)` or `pinthreads(:sockets)`),
2) by providing a logical specification via helper functions (e.g. `pinthreads(numa(2, 1:4))`),
3) explicitly (e.g. `0:3` or `[0,12,4]`).

See `??pinthreads` for more information on these variants and keyword arguments.

# Keyword arguments

If set, the keyword argument `nthreads` serves as a cutoff, that is, the first
`min(length(cpuids), nthreads)` Julia threads will get pinned.

The keyword argument `threadpool` can be used to indicate the pool of Julia threads that
should be considered. Supported values are `:default` (default), `:interactive`, or `:all`.
On Julia >= 1.11, there is also experimental support for `:gc`.

If `force=false`, threads will only get pinned if this is the very first pin attempt
(otherwise the call is a no-op). This may be particularly useful for packages that merely
want to specify an (overrulable) "default pinning".

The option `warn` toggles general warnings, such as unwanted interference with BLAS thread
settings.

# Extended help

**1) Predefined Symbols**

* `:cputhreads` or `:compact`: successively pin to all available CPU-threads.
* `:cores`: spread threads across all available cores, only use hyperthreads if necessary.
* `:sockets`: spread threads across sockets (round-robin), only use hyperthreads if
              necessary. Set `compact=true` to get compact pinning within each socket.
* `:numa`: spread threads across NUMA/memory domains (round-robin), only use hyperthreads
           if necessary. Set `compact=true` to get compact pinning within each NUMA/memory
           domain.
* `:random`: pin threads randomly to CPU-threads
* `:current`: pin threads to the CPU-threads they are currently running on
* `:firstn`: pin threads to CPU-threads in order according to there OS index.
* `:affinitymask`: pin threads to different CPU-threads in accordance with the process
                   affinity. By default, `hyperthreads_last=true`.

**2) Logical Specification**

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

**3) Explicit**

Simply provide an `AbstractVector{<:Integer}` of CPU IDs. The latter are expected to be
"physical" OS indices (e.g. from hwloc or lscpu) that start at zero!
"""
function pinthreads end

"""
    with_pinthreads(f::F, args...;
        soft = false,
        kwargs...
    )

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
function with_pinthreads end

"""
    unpinthread(; threadid::Integer = Threads.threadid())

Unpins the given Julia thread by setting the affinity mask to all unity.
Afterwards, the OS is free to move the Julia thread from one CPU thread to another.
"""
function unpinthread end

"""
    unpinthreads(; threadpool::Symbol = :default)

Unpins all Julia threads by setting the affinity mask of all threads to all unity.
Afterwards, the OS is free to move any Julia thread from one CPU thread to another.
"""
function unpinthreads end

"""
Set the affinity of a Julia thread to the given CPU-threads.

*Examples:*
* `setaffinity(socket(1))` # set the affinity to the first socket
* `setaffinity(numa(2))` # set the affinity to the second NUMA domain
* `setaffinity(socket(1, 1:3))` # set the affinity to the first three cores in the first NUMA domain
* `setaffinity([1,3,5])` # set the affinity to the CPU-threads with the IDs 1, 3, and 5.
"""
function setaffinity_cpuids end

"""
    setaffinity(mask; threadid = Threads.threadid())

Set the affinity of a Julia thread based on the given mask (a vector of ones and zeros).
"""
function setaffinity end

# OpenBLAS
"""
    openblas_setaffinity(mask; threadid)

Set the affinity of the OpenBLAS thread with the given `threadid` to the given `mask`.

The input `mask` should be one of the following:
   * a `BitArray` to indicate the mask directly
   * a vector of cpuids (in which case the mask will be constructed automatically)
"""
function openblas_setaffinity end

"""
Set the affinity of the OpenBLAS thread to the given CPU-threads.

*Examples:*
* `openblas_setaffinity_cpuids(socket(1))` # set the affinity to the first socket
* `openblas_setaffinity_cpuids(numa(2))` # set the affinity to the second NUMA domain
* `openblas_setaffinity_cpuids(socket(1, 1:3))` # set the affinity to the first three cores in the first NUMA domain
* `openblas_setaffinity_cpuids([1,3,5])` # set the affinity to the CPU-threads with the IDs 1, 3, and 5.
"""
function openblas_setaffinity_cpuids end

"""
    openblas_pinthread(cpuid; threadid)

Pin the OpenBLAS thread with the given `threadid` to the given CPU-thread (`cpuid`).
"""
function openblas_pinthread end

"""
    openblas_pinthreads(cpuids; nthreads = BLAS.get_num_threads())

Pin the OpenBLAS threads to the given CPU IDs. The optional keyword argument `nthreads`
serves as a cutoff.
"""
function openblas_pinthreads end

"""
    openblas_unpinthread(; threadid)

Unpins the OpenBLAS thread with the given `threadid` by setting its affinity mask to all
unity. Afterwards, the OS is free to move the OpenBLAS thread from one CPU thread
to another.
"""
function openblas_unpinthread end

"""
    openblas_unpinthreads(; threadpool = :default)

Unpins all OpenBLAS threads by setting their affinity masks all unity.
Afterwards, the OS is free to move any OpenBLAS thread from one CPU thread to another.
"""
function openblas_unpinthreads end

##
##
## -------------- Internals / Implementation --------------
##
##

module Pinning

import ThreadPinning: pinthread, pinthreads, with_pinthreads, unpinthread, unpinthreads
import ThreadPinning: setaffinity, setaffinity_cpuids
import ThreadPinning: openblas_setaffinity, openblas_setaffinity_cpuids,
                      openblas_pinthread, openblas_pinthreads,
                      openblas_unpinthread, openblas_unpinthreads
using ThreadPinning: ThreadPinning, getaffinity, getcpuids
import ThreadPinningCore
import SysInfo
import ..Utility
import ..SLURM
using LinearAlgebra: BLAS

# direct forwards
setaffinity(mask; kwargs...) = ThreadPinningCore.setaffinity(mask; kwargs...)
unpinthread(; kwargs...) = ThreadPinningCore.unpinthread(; kwargs...)
unpinthreads(; kwargs...) = ThreadPinningCore.unpinthreads(; kwargs...)
function openblas_setaffinity(mask; kwargs...)
    ThreadPinningCore.openblas_setaffinity(mask; kwargs...)
end
openblas_unpinthread(; kwargs...) = ThreadPinningCore.openblas_unpinthread(; kwargs...)
openblas_unpinthreads(; kwargs...) = ThreadPinningCore.openblas_unpinthreads(; kwargs...)

function with_pinthreads(
        f::F,
        args...;
        soft = false,
        threadpool::Symbol = :default,
        kwargs...
) where {F}
    tids = ThreadPinningCore.threadids(; threadpool)
    masks_prior = [getaffinity(; threadid = i) for i in tids]
    cpuids_prior = getcpuids()
    pinthreads(args...; threadpool, kwargs...)
    local res
    try
        res = f()
    finally
        soft || pinthreads(cpuids_prior)
        for (i, threadid) in pairs(tids)
            setaffinity(masks_prior[i]; threadid)
        end
    end
    return res
end

function setaffinity_cpuids(cpuids::AbstractVector{<:Integer}; kwargs...)
    _check_cpuids(cpuids)
    mask = Utility.cpuids2affinitymask(cpuids)
    ThreadPinningCore.setaffinity(mask; kwargs...)
    return
end

function openblas_setaffinity_cpuids(cpuids::AbstractVector{<:Integer}; kwargs...)
    _check_cpuids(cpuids)
    mask = Utility.cpuids2affinitymask(cpuids)
    ThreadPinningCore.openblas_setaffinity(BitArray(mask); kwargs...)
    return
end

for (_pinthread, _pinthreads, _nthreads) in (
    (:pinthread, :pinthreads, :(Threads.nthreads)), (
        :openblas_pinthread, :openblas_pinthreads, :(BLAS.get_num_threads)))
    @eval begin
        # core functions (pinning based on cpuids)
        function $(_pinthread)(
                cpuid::Integer; warn::Bool = ThreadPinningCore.is_first_pin_attempt(), kwargs...)
            if warn
                # _check_environment()
                _check_slurm()
            end
            _check_cpuid(cpuid)
            return ThreadPinningCore.$(_pinthread)(cpuid; kwargs...)
        end

        function $(_pinthreads)(cpuids::AbstractVector{<:Integer};
                warn::Bool = ThreadPinningCore.is_first_pin_attempt(),
                kwargs...)
            _check_cpuids(cpuids)
            if warn
                # _check_environment()
                _check_slurm()
            end
            ThreadPinningCore.$(_pinthreads)(cpuids; kwargs...)
            return
        end

        # concatenation
        function $(_pinthreads)(cpuids_vec::AbstractVector{T};
                kwargs...) where {T <: AbstractVector{<:Integer}}
            return $(_pinthreads)(reduce(vcat, cpuids_vec); kwargs...)
        end
        function $(_pinthreads)(cpuids_args::AbstractVector{<:Integer}...; kwargs...)
            return $(_pinthreads)(reduce(vcat, cpuids_args); kwargs...)
        end

        # convenience symbols
        $(_pinthreads)(symb::Symbol; kwargs...) = $(_pinthreads)(Val(symb); kwargs...)
        function $(_pinthreads)(
                ::Union{Val{:compact}, Val{:threads}, Val{:cputhreads}}; kwargs...)
            $(_pinthreads)(SysInfo.node(; compact = true); kwargs...)
        end
        function $(_pinthreads)(::Union{Val{:cores}}; kwargs...)
            $(_pinthreads)(SysInfo.node(; compact = false); kwargs...)
        end
        function $(_pinthreads)(::Val{:sockets}; compact = false, kwargs...)
            $(_pinthreads)(SysInfo.sockets(; compact); kwargs...)
        end
        function $(_pinthreads)(
                ::Union{Val{:numa}, Val{:numas}}; compact = false, kwargs...)
            $(_pinthreads)(SysInfo.numas(; compact); kwargs...)
        end
        function $(_pinthreads)(::Val{:random}; kwargs...)
            $(_pinthreads)(SysInfo.node(; shuffle = true); kwargs...)
        end
        function $(_pinthreads)(::Val{:firstn}; kwargs...)
            $(_pinthreads)(sort(SysInfo.cpuids()); kwargs...)
        end
        function $(_pinthreads)(::Val{:affinitymask}; hyperthreads_last = true,
                nthreads = $(_nthreads)(), warn = false, kwargs...)
            mask = ThreadPinningCore.get_initial_affinity_mask()
            isnothing(mask) && error("No (or non-unique) external affinity mask set.")
            if hyperthreads_last
                cpuids = Utility.affinitymask2cpuids(mask)
            else
                cpuids = Utility.affinitymask2cpuids(mask; compact = true)
            end
            $(_pinthreads)(cpuids; nthreads, warn, kwargs...)
            return
        end
    end
end

# doesn't really make much sense for BLAS
function pinthreads(::Val{:current}; kwargs...)
    pinthreads(ThreadPinningCore.getcpuids(); kwargs...)
end

# Potentially throw warnings if the environment is such that thread pinning might not work.
# function _check_environment()
#     if Base.Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
#         @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can "*
#               "spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` "*
#               "to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
#     end
#     return
# end

function _check_slurm()
    if SLURM.isslurmjob() && !SLURM.hasfullnode()
        @warn("You seem to be running in a SLURM allocation that doesn't cover the entire "*
              "node. Most likely, only a subset of the available CPU-threads will be "*
              "accessible. This might lead to unexpected/wrong pinning results.")
    end
    return
end

function _check_cpuid(cpuid)
    if !(cpuid in SysInfo.cpuids())
        throw(ArgumentError("Invalid CPU ID encountered. See `ThreadPinning.cpuids()` " *
                            "for all valid CPU IDs on the system."))
    end
end

function _check_cpuids(cpuids)
    if !all(c -> c in SysInfo.cpuids(), cpuids)
        valid_cpuids = SysInfo.cpuids()
        problem_cpuids = filter(c -> !(c in valid_cpuids), cpuids)
        throw(ArgumentError("Invalid CPU ID(s) encountered: $(problem_cpuids). See " *
                            "`ThreadPinning.cpuids()` for all valid CPU IDs on the system."))
    end
    return
end

end # module
