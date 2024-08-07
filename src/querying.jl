##
##
## -------------- API --------------
##
##

"""
    getcpuid(; threadid = nothing)

Returns the ID of the CPU thread on which a Julia thread is currently running.

If `threadid=nothing` (default), we query the id directly from the calling thread.
"""
function getcpuid end

"""
    getcpuids(; threadpool = :default)

Returns the IDs of the CPU-threads on which the Julia threads are currently running on.

The keyword argument `threadpool` (default: `:default`) may be used to specify a specific
thread pool.
"""
function getcpuids end

"""
    getaffinity(; threadid = Threads.threadid(), cutoff = cpuidlimit())

Get the thread affinity of a Julia thread. Returns the affinity mask as a vector of zeros
and ones.
By default, the mask is cut off at `Sys.CPU_THREADS`. This can be tuned via the
`cutoff` keyword argument (`nothing` means no cutoff).
"""
function getaffinity end

"""
    getnumanode(; threadid = nothing)

Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on
which the calling thread is currently running. A `threadid` may be provided to consider
a Julia thread that is different from the calling one.
"""
function getnumanode end

"""
    getnumanodes(; threadpool = :default)

Returns the IDs (starting at zero) of the NUMA nodes corresponding to the CPU threads on
which the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to consider only those
Julia threads that belong to a specific thread pool.
"""
function getnumanodes end

"""
    getispinned(; threadpool = :default)

Returns the results of `ispinned` for all Julia threads.

The keyword argument `threadpool` (default: `:default`) may be used to specify a specific
thread pool.
"""
function getispinned end

"""
Returns the CPU IDs that belong to core `i` (logical index, starts at 1).
Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the CPU-threads.
"""
function core end

"""
Returns the CPU IDs that belong to the `i`th NUMA domain (logical index, starts at 1).
By default, an "cores before hyperthreads" ordering is used. Set `compact=true` if you want
compact ordering. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the CPU-threads.
"""
function numa end

"""
Returns the CPU IDs that belong to the `i`th CPU/socket (logical index, starts at 1).
By default, an "cores before hyperthreads" ordering is used. Set `compact=true` if you want
compact ordering. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the CPU-threads.
"""
function socket end

"""
Returns all CPU IDs of the system/compute node (logical index, starts at 1).
By default, an "cores before hyperthreads" ordering is used. Set `compact=true` if you want
compact ordering. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the CPU-threads.
"""
function node end

"""
Returns the CPU IDs of the system as obtained by a round-robin scattering
between CPU cores. This is the same as `nodes(; compact=false)`.
Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the sockets.
"""
function cores end

"""
Returns the CPU IDs of the system as obtained by a round-robin scattering
between sockets. By default, within each socket, a round-robin ordering among CPU cores is
used ("cores before hyperthreads"). Provide `compact=true` to get compact ordering within
each socket. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the sockets.
"""
function sockets end

"""
Returns the CPU IDs of the system as obtained by a round-robin scattering
between NUMA domains. Within each NUMA domain, a round-robin ordering among
CPU cores is used ("cores before hyperthreads"). Provide `compact=true` to get compact ordering
within each NUMA domain. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the sockets.
"""
function numas end

"""
    printaffinity(; threadid::Integer = Threads.threadid())

Print the affinity mask of the Julia thread.

The keyword argument `groupby` may be used to change how CPU-threads are grouped visually.
It defaults to `groupby=:socket`. Other valid values are `:numa` and `:core`.
"""
function printaffinity end

"""
    printaffinities(; threadpool = :default, kwargs...)

Print the affinity masks of all Julia threads. See [`printaffinity`](@ref) for options.
"""
function printaffinities end

"""
Visualize the affinity mask of a Julia thread. Many of the keyword options of `threadinfo`
work here as well.
"""
function visualize_affinity end

"""
    ispinned(; threadid = Threads.threadid())

Returns `true` if the thread is pinned, that is, if it has an affinity mask that
highlights a single CPU-thread.
"""
function ispinned end

"""
Check whether simultaneous multithreading (SMT) / "hyperthreading" is enabled.
"""
function hyperthreading_is_enabled end

"""
Check whether the given CPU-thread is a SMT-thread / "hyperthread" (i.e. it is not the
first CPU-thread in the CPU-core).
"""
function ishyperthread end

"""
Returns true if the given CPU-thread lies inside of a CPU-core that has the highest power
efficiency of all the CPU-cores (i.e. an efficiency value of 1). If
there is only a single CPU-core kind, the return value is false for all CPU IDs.
"""
function isefficiencycore end

"Number of CPU-threads"
function ncputhreads end

"Number of cores (i.e. excluding hyperthreads)"
function ncores end

"Number of NUMA nodes"
function nnuma end

"Number of CPU-sockets / CPUs"
function nsockets end

"Number of different kinds of cores (e.g. efficiency and performance cores)."
function ncorekinds end

"""
The number of SMT-threads in a core. If this number varies between different cores, the
maximum is returned.
"""
function nsmt end

"""
All valid CPU IDs of the system (sorted).
"""
function cpuids end

"""
Returns the logical index (starts at 1) that corresponds to the given
CPU ID ("physical" OS index).
"""
function id end

"""
Returns the CPU ID ("physical" OS index) that corresponds to the given
logical index (starts at 1).
"""
function cpuid end

# OpenBLAS
"""
    openblas_getaffinity(; threadid, convert = true)

Query the affinity of the OpenBLAS thread with the given `threadid`
(typically `1:BLAS.get_num_threads()`).
By default, returns a vector respresenting the mask.
If `convert=false` a `Ccpu_set_t` is returned instead.
"""
function openblas_getaffinity end

"""
    openblas_getcpuid(; threadid)

Get the id of the CPU thread on which the OpenBLAS thread with the given `threadid` is
running on **according to its affinity**.

**Note:** If the OpenBLAS thread has not been pinned before, this function will error
because the affinity mask highlights more than a single CPU thread by default.
"""
function openblas_getcpuid end

"""
    openblas_getcpuids()

Get the ids of the CPU threads on which the OpenBLAS threads are running on
**according to their affinity**. See [`openblas_getcpuid`](@ref) for more information."
"""
function openblas_getcpuids end

"""
    openblas_ispinned(; threadid)

Check if the OpenBLAS thread is pinned to a single CPU thread.
"""
function openblas_ispinned end

"""
    openblas_printaffinity(; threadid)

Print the affinity of an OpenBLAS thread.
"""
function openblas_printaffinity end

"Print the affinities of all OpenBLAS threads."
function openblas_printaffinities end

##
##
## -------------- Internals / Implementation --------------
##
##

module Querying

import ThreadPinning: getcpuid, getcpuids, getnumanode, getnumanodes, getispinned
import ThreadPinning: printaffinity, printaffinities, getaffinity, visualize_affinity
import ThreadPinning: ispinned, ishyperthread, hyperthreading_is_enabled, isefficiencycore
import ThreadPinning: ncputhreads, ncores, nnuma, nsockets, ncorekinds, nsmt
import ThreadPinning: core, numa, socket, node, cores, sockets, numas, cpuids
import ThreadPinning: id, cpuid
import ThreadPinning: openblas_getaffinity, openblas_getcpuid, openblas_getcpuids,
                      openblas_ispinned, openblas_printaffinity, openblas_printaffinities

using ThreadPinning: getstdout
using SysInfo: SysInfo
using ThreadPinningCore: ThreadPinningCore
using StableTasks: @fetchfrom
import ..ThreadInfo
import ..Utility
using LinearAlgebra: BLAS

# forwarding to SysInfo
ncputhreads() = SysInfo.ncputhreads()
ncores() = SysInfo.ncores()
nnuma() = SysInfo.nnuma()
nsockets() = SysInfo.nsockets()
ncorekinds() = SysInfo.ncorekinds()
nsmt() = SysInfo.nsmt()
id(cpuid::Integer) = SysInfo.id(cpuid)
cpuid(id::Integer) = SysInfo.cpuid(id)
core(args...; kwargs...) = SysInfo.core(args...; kwargs...)
socket(args...; kwargs...) = SysInfo.socket(args...; kwargs...)
numa(args...; kwargs...) = SysInfo.numa(args...; kwargs...)
node(args...; kwargs...) = SysInfo.node(args...; kwargs...)
cores(args...; kwargs...) = SysInfo.cores(args...; kwargs...)
sockets(args...; kwargs...) = SysInfo.sockets(args...; kwargs...)
numas(args...; kwargs...) = SysInfo.numas(args...; kwargs...)
cpuids(args...; kwargs...) = sort(SysInfo.cpuids(args...; kwargs...))
hyperthreading_is_enabled() = SysInfo.hyperthreading_is_enabled()
ishyperthread(cpuid::Integer) = SysInfo.ishyperthread(cpuid)
isefficiencycore(cpuid::Integer) = SysInfo.isefficiencycore(cpuid)

# forwarding to ThreadPinningCore
getcpuid(; kwargs...) = ThreadPinningCore.getcpuid(; kwargs...)
getcpuids(; kwargs...) = ThreadPinningCore.getcpuids(; kwargs...)
getaffinity(; kwargs...) = ThreadPinningCore.getaffinity(; kwargs...)
ispinned(; kwargs...) = ThreadPinningCore.ispinned(; kwargs...)
openblas_getaffinity(; kwargs...) = ThreadPinningCore.openblas_getaffinity(; kwargs...)
openblas_getcpuid(; kwargs...) = ThreadPinningCore.openblas_getcpuid(; kwargs...)
openblas_getcpuids(; kwargs...) = ThreadPinningCore.openblas_getcpuids(; kwargs...)
openblas_ispinned(; kwargs...) = ThreadPinningCore.openblas_ispinned(; kwargs...)

# no (direct) forwarding
function getispinned(; threadpool = :default)
    tids = ThreadPinningCore.threadids(; threadpool)
    return [ispinned(; threadid = t) for t in tids]
end

function printaffinity(; threadid = Threads.threadid(), io = getstdout(), kwargs...)
    mask = ThreadPinningCore.getaffinity(; threadid)
    str = _affinity_to_string(mask; kwargs...)
    print(io, rpad("$(threadid):", 5))
    println(io, str)
    return
end
function printaffinities(; threadpool = :default, io = getstdout(), kwargs...)
    tids = ThreadPinningCore.threadids(; threadpool)
    for threadid in tids
        printaffinity(; threadid, io, kwargs...)
    end
    return
end
function openblas_printaffinity(;
        threadid = Threads.threadid(), io = getstdout(), kwargs...)
    mask = ThreadPinningCore.openblas_getaffinity(; threadid)
    str = _affinity_to_string(mask; kwargs...)
    print(io, rpad("$(threadid):", 5))
    println(io, str)
    return
end
function openblas_printaffinities(; io = getstdout(), kwargs...)
    tids = 1:BLAS.get_num_threads()
    for threadid in tids
        openblas_printaffinity(; threadid, io, kwargs...)
    end
    return
end
function _affinity_to_string(mask; groupby = :sockets)
    if groupby in (:numa, :NUMA)
        f = SysInfo.numa
        nf = SysInfo.nnuma
    elseif groupby in (:core, :cores)
        f = SysInfo.core
        nf = SysInfo.ncores
    else
        f = SysInfo.socket
        nf = SysInfo.nsockets
    end
    str = "|"
    for s in 1:nf()
        cpuids = f(s)
        idcs = cpuids .+ 1
        x = Int.(mask[idcs])
        str = string(str, x..., "|")
    end
    return str
end

function visualize_affinity(
        io = getstdout(); threadid::Integer = Threads.threadid(), mask = nothing)
    if isnothing(mask)
        mask = getaffinity(; threadid)
    end
    cpuids = Utility.affinitymask2cpuids(mask)
    println(io)
    printstyled(io, "Thread affinity of Julia thread $(threadid)."; bold = :true)
    println(io)
    ThreadInfo.visualization(io; threads_cpuids = cpuids, legend = false)
    printstyled(io, "(The highlighted CPU-threads are set to 1 in the affinity mask.)";
        color = :light_black)
    println(io)
    return
end

function getnumanode(; threadid::Union{Integer, Nothing} = nothing)
    cpuid = isnothing(threadid) ? getcpuid() : getcpuid(; threadid)
    return SysInfo.cpuid_to_numanode(cpuid)
end
function getnumanodes(; threadpool = :default)::Vector{Int}
    if !(threadpool in (:all, :default, :interactive))
        throw(ArgumentError("Unknown value for `threadpool` keyword argument. " *
                            "Supported values are `:all`, `:default`, and " *
                            "`:interactive`."))
    end
    tids_pool = ThreadPinningCore.threadids(; threadpool)
    numanodes = zeros(Int, length(tids_pool))
    for (i, threadid) in pairs(tids_pool)
        numanodes[i] = getnumanode(; threadid)
    end
    return numanodes
end

end # module
