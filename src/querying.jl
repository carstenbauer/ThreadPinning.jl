##
##
## -------------- API --------------
##
##

"""
Returns `true` if the thread is pinned, i.e. if it has an affinity mask that comprises a
single CPU-thread.
"""
function ispinned end

"""
Returns the ID of the CPU thread on which the calling thread is currently running.
"""
function getcpuid end

"""
Returns the IDs of the CPU-threads on which the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to specify a specific
thread pool.
"""
function getcpuids end

function core end

function numa end

function socket end

function node end

function cores end

function sockets end

function numas end

"""
All valid CPU IDs on the system.
"""
function cpuids end

"""
Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on
which the calling thread is currently running. A `threadid` may be provided to consider
a Julia thread that is different from the calling one.
"""
function getnumanode end

"""
Returns the IDs (starting at zero) of the NUMA nodes corresponding to the CPU threads on
which the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to consider only those
Julia threads that belong to a specific thread pool.
"""
function getnumanodes end

"""
Print the affinity mask of a Julia thread.

The keyword argument `groupby` may be used to change how CPU-threads are grouped visually.
It defaults to `groupby=:socket`. Other valid values are `:numa` and `:core`.
"""
function printaffinity end

"""
Print the affinity masks of all Julia threads. See [`printaffinity`](@ref) for options.
"""
function printaffinities end

"""
Visualize the affinity mask of a Julia thread. Many of the keyword options of `threadinfo`
work here as well.
"""
function visualize_affinity end

"""
Get the thread affinity of a Julia thread. Returns the affinity mask as a vector of zeros
and ones.
By default, the mask is cut off at `Sys.CPU_THREADS`. This can be tuned via the
`cutoff` keyword argument (`nothing` means no cutoff).
"""
function getaffinity end

"""
Check whether simultaneous multithreading (SMT) / "hyperthreading" is enabled.
"""
function hyperthreading_is_enabled end

"""
Check whether the given CPU-thread is a SMT-thread / "hyperthread" (i.e. it is not the
first CPU-thread in the CPU-core).
"""
function ishyperthread end

"Number of CPU-threads"
function ncputhreads end

"Number of cores (i.e. excluding hyperthreads)"
function ncores end

"Number of NUMA nodes"
function nnuma end

"Number of CPU sockets"
function nsockets end

"Number of CPU-threads per core"
function ncputhreads_per_core end

"Number of CPU-threads per NUMA domain"
function ncputhreads_per_numa end

"Number of CPU-threads per socket"
function ncputhreads_per_socket end

"Number of CPU-cores per NUMA domain"
function ncores_per_numa end

"Number of CPU-cores per socket"
function ncores_per_socket end

##
##
## -------------- Internals / Implementation --------------
##
##

module Querying

import ThreadPinning: getcpuid, getcpuids, getnumanode, getnumanodes
import ThreadPinning: printaffinity, printaffinities, getaffinity, visualize_affinity
import ThreadPinning: ispinned, ishyperthread, hyperthreading_is_enabled
import ThreadPinning: ncputhreads, ncores, nnuma, nsockets, ncputhreads_per_core
import ThreadPinning: core, numa, socket, node, cores, sockets, numas, cpuids

# ncputhreads_per_numa, ncputhreads_per_socket, ncores_per_numa, ncores_per_socket,
#                       cpuids_all, cpuids_per_core, cpuids_per_numa, cpuids_per_socket,
#                       cpuids_per_node,

using ThreadPinning: getstdout
using SysInfo: SysInfo
using ThreadPinningCore: ThreadPinningCore
using StableTasks: @fetchfrom
import ..ThreadInfo
import ..Utility

# forwarding to SysInfo
ncputhreads() = SysInfo.ncputhreads()
ncores() = SysInfo.ncores()
nnuma() = SysInfo.nnuma()
nsockets() = SysInfo.nsockets()
core(args...; kwargs...) = SysInfo.core(args...; kwargs...)
socket(args...; kwargs...) = SysInfo.socket(args...; kwargs...)
numa(args...; kwargs...) = SysInfo.numa(args...; kwargs...)
node(args...; kwargs...) = SysInfo.node(args...; kwargs...)
cores(args...; kwargs...) = SysInfo.cores(args...; kwargs...)
sockets(args...; kwargs...) = SysInfo.sockets(args...; kwargs...)
numas(args...; kwargs...) = SysInfo.numas(args...; kwargs...)
cpuids(args...; kwargs...) = collect(SysInfo.cpuids(args...; kwargs...))
hyperthreading_is_enabled() = SysInfo.hyperthreading_is_enabled()
ishyperthread(cpuid::Integer) = SysInfo.ishyperthread(cpuid)

# forwarding to ThreadPinningCore
getcpuid(; kwargs...) = ThreadPinningCore.getcpuid(; kwargs...)
getcpuids(; kwargs...) = ThreadPinningCore.getcpuids(; kwargs...)
getaffinity(; kwargs...) = ThreadPinningCore.getaffinity(; kwargs...)
ispinned(; kwargs...) = ThreadPinningCore.ispinned(; kwargs...)

# no (direct) forwarding
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
function _affinity_to_string(mask; groupby = :sockets)
    bitstr = join(mask)[1:SysInfo.ncputhreads()]
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
        str = string(str, bitstr[idcs], "|")
    end
    return str
end

function visualize_affinity(io = getstdout(); threadid::Integer = Threads.threadid())
    mask = getaffinity(; threadid)
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

# ncputhreads_per_core() = length.(unsafe_cpuids_per_core())

# ncputhreads_per_numa() = length.(unsafe_cpuids_per_numa())

# ncputhreads_per_socket() = length.(unsafe_cpuids_per_socket())

# ncores_per_numa() = count.(!ishyperthread, unsafe_cpuids_per_numa())

# ncores_per_socket() = count.(!ishyperthread, unsafe_cpuids_per_socket())

end # module
