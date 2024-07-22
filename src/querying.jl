## API

"""
Returns the ID of the CPU thread on which the calling thread
(or the thread with the given ID) is currently running
"""
function getcpuid end

"""
Returns the IDs of the CPU-threads on which the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to specify a specific
thread pool.
"""
function getcpuids end

"""
Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on which
the calling thread is currently running. A `threadid` may be provided to consider a Julia
thread that is different from the calling one.
"""
function getnumanode end

"""
Returns the IDs (starting at zero) of the NUMA nodes corresponding to the CPU threads on which
the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to consider only those
Julia threads that belong to a specific thread pool.
"""
function getnumanodes end

"""
$(SIGNATURES)Print the affinity mask of a Julia thread.
"""
function print_affinity_mask end

"""
$(SIGNATURES)Print the affinity masks of all Julia threads.
"""
function print_affinity_masks end

"""
$(SIGNATURES)Get the affinity mask of the given Julia Thread
"""
function get_affinity_mask end

"""
Returns `true` if the thread is pinned, i.e. if it has an affinity mask that comprises a single CPU-thread.
"""
function ispinned end

"""
Check whether simultaneous multithreading (SMT) / "hyperthreading" is enabled.
"""
function hyperthreading_is_enabled end

"$(SIGNATURES)Check whether the given CPU-thread is a hyperthread (i.e. the second
CPU-thread within a CPU-core)."
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

"Returns a `Vector{Int}` which lists all valid CPUIDs. There is no guarantee about the
order except that it is the same as in `lscpu`."
function cpuids_all end

"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
physical cores"
function cpuids_per_core end

"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
NUMA domains. Within each memory domain, physical cores come first. Set `compact=true` to
get compact ordering instead.
"""
function cpuids_per_numa end

"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
CPU sockets. Within each socket, physical cores come first. Set `compact=true` to get
compact ordering instead.
"""
function cpuids_per_socket end

"""
$(SIGNATURES)
Returns a `Vector{Int}` which indicates the CPUIDs associated with the available node.
Physical cores come first. Set `compact=true` to get compact ordering.
"""
function cpuids_per_node end

"""
$(SIGNATURES)
Represents the CPU ID domain of core `i` (logical index, starts at 1). Uses compact ordering
by default. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function core end

"""
$(SIGNATURES)
Represents the CPU ID domain of NUMA/memory domain `i` (logical index, starts at 1). By
default, cores will be used first and hyperthreads will only be used if necessary. Provide
`compact=true` to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function numa end

"""
$(SIGNATURES)
Represents the CPU ID domain of socket `i` (logical index, starts at 1). By default, cores
will be used first and hyperthreads will only be used if necessary. Provide `compact=true`
to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function socket end

"""
$(SIGNATURES)
Represents the CPU ID domain of the entire node/system. By default, cores will be used first
and hyperthreads will only be used if necessary. Provide `compact=true` to get compact
ordering instead. Set `shuffle=true` to randomize. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function node end

"""
$(SIGNATURES)
Represents the CPU IDs of the system as obtained by a round-robin scattering
between sockets. By default, within each socket, cores will be used first and hyperthreads
will only be used if necessary. Provide `compact=true` to get compact ordering within each
socket. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function sockets end

"""
$(SIGNATURES)
Represents the CPU IDs of the system as obtained by a round-robin scattering
between NUMA/memory domain. By default, within each memory domain, cores will be used first
and hyperthreads will only be used if necessary. Provide `compact=true` to get compact
ordering within each memory domain. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function numas end

## Internals / Implementation
module Querying

import ThreadPinning: getcpuid, getcpuids, getnumanode, getnumanodes, print_affinity_mask,
                      print_affinity_masks, get_affinity_mask, ispinned,
                      hyperthreading_is_enabled, ishyperthread, ncputhreads, ncores, nnuma,
                      nsockets, ncputhreads_per_core, ncputhreads_per_numa,
                      ncputhreads_per_socket, ncores_per_numa, ncores_per_socket,
                      cpuids_all, cpuids_per_core, cpuids_per_numa, cpuids_per_socket,
                      cpuids_per_node, core, numa, socket, node, sockets, numas

using ThreadPinning: getstdout
using SysInfo: SysInfo
using ThreadPinningCore: ThreadPinningCore
using StableTasks: @spawnat

# forwarding (mostly)
hyperthreading_is_enabled() = SysInfo.hyperthreading_is_enabled()
ncputhreads() = SysInfo.ncputhreads()
ncores() = SysInfo.ncores()
nnuma() = SysInfo.nnuma()
nsockets() = SysInfo.nsockets()

getcpuid() = ThreadPinningCore.getcpuid()
getcpuid(threadid::Integer) = fetch(@spawnat threadid getcpuid())

# new
function getcpuids(; threadpool = :default)::Vector{Int}
    if !(threadpool in (:all, :default, :interactive))
        throw(ArgumentError("Unknown value for `threadpool` keyword argument. " *
                            "Supported values are `:all`, `:default`, and " *
                            "`:interactive`."))
    end
    tids_pool = ThreadPinningCore.threadids(; threadpool)
    nt = length(tids_pool)
    cpuids = zeros(Int, nt)
    for (i, tid) in pairs(tids_pool)
        cpuids[i] = getcpuids(tid)
    end
    return cpuids
end

function getnumanode()
    cpuid = getcpuid()
    for (i, cs_numa) in enumerate(unsafe_cpuids_per_numa())
        if cpuid in cs_numa
            return i - 1
        end
    end
    return -1
end
getnumanode(threadid::Integer) = fetch(@spawnat threadid getnumanode())
function getnumanodes(; threadpool = :default)::Vector{Int}
    @static if VERSION >= v"1.9-"
        if !(threadpool in (:all, :default, :interactive))
            throw(ArgumentError("Unknown value for `threadpool` keyword argument. " *
                                "Supported values are `:all`, `:default`, and " *
                                "`:interactive`."))
        end
        tids_pool = threadids(threadpool)
        nt = length(tids_pool)
        numanodes = zeros(Int, nt)
        for (i, tid) in pairs(tids_pool)
            numanodes[i] = fetch(@spawnat tid getnumanode())
        end
    else
        nt = nthreads()
        numanodes = zeros(Int, nt)
        @threads :static for tid in 1:nt
            numanodes[tid] = getnumanode()
        end
    end
    return numanodes
end

function print_affinity_mask(tid = Threads.threadid(); io = getstdout(), kwargs...)
    mask = ThreadPinningCore.getaffinity(; tid)
    str = _affinity_mask_to_string(mask; kwargs...)
    print(io, rpad("$(tid):", 5))
    println(io, str)
end
function print_affinity_masks(; threadpool = :default, io = getstdout(), kwargs...)
    tids = ThreadPinningCore.threadids(; threadpool)
    for tid in tids
        print_affinity_mask(tid; io, kwargs...)
    end
    return nothing
end
function _affinity_mask_to_string(mask; groupby = :sockets)
    bitstr = join(mask)[1:ncputhreads()]
    if groupby in (:numa, :NUMA)
        cpuids_per_X = cpuids_per_numa
        nX = nnuma
    elseif groupby in (:core, :cores)
        cpuids_per_X = cpuids_per_core
        nX = ncores
    else
        cpuids_per_X = cpuids_per_socket
        nX = nsockets
    end
    str = "|"
    for s in 1:nX()
        cpuids_s = cpuids_per_X()[s]
        idcs = [findfirst(isequal(c), unsafe_cpuids_all()) for c in cpuids_s]
        str = string(str, bitstr[idcs], "|")
    end
    return str
end

get_affinity_mask(tid = threadid()) = ThreadPinningCore.getaffinity(; tid)

function get_cpuids_from_affinity_mask(tid = threadid())
    affinitymask2cpuids(get_affinity_mask(tid))
end
function affinitymask2cpuids(mask)
    [unsafe_cpuids_all()[i] for (i, v) in enumerate(mask) if v == 1]
end

ispinned(tid = threadid()) = ThreadPinningCore.ispinned(; tid)

# Unsafe because they directly return the fields instead of copies (be warry when modiying!)
unsafe_cpuids_all() = sysinfo().cpuids
unsafe_cpuids_per_core() = sysinfo().cpuids_cores
unsafe_cpuids_per_numa() = sysinfo().cpuids_numa
unsafe_cpuids_per_socket() = sysinfo().cpuids_sockets
unsafe_cpuids_per_node() = sysinfo().cpuids_node

ishyperthread(cpuid::Integer) = sysinfo().ishyperthread[_cpuidx(cpuid)]

ncputhreads_per_core() = length.(unsafe_cpuids_per_core())

ncputhreads_per_numa() = length.(unsafe_cpuids_per_numa())

ncputhreads_per_socket() = length.(unsafe_cpuids_per_socket())

ncores_per_numa() = count.(!ishyperthread, unsafe_cpuids_per_numa())

ncores_per_socket() = count.(!ishyperthread, unsafe_cpuids_per_socket())

cpuids_all() = deepcopy(unsafe_cpuids_all())

cpuids_per_core() = deepcopy(unsafe_cpuids_per_core())

function cpuids_per_numa(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_numa())
    else
        data = getsortedby([IOSID, INUMA], (INUMA, ICORE))
        return Vector{Int}[data[data[:, 2] .== n, 1] for n in 1:nnuma()]
    end
end

function cpuids_per_socket(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_socket())
    else
        data = getsortedby([IOSID, ISOCKET], (ISOCKET, ICORE))
        return Vector{Int}[data[data[:, 2] .== s, 1] for s in 1:nsockets()]
    end
end

function cpuids_per_node(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_node())
    else
        return Vector{Int}(getsortedby(IOSID, (ICORE, ISMT, ISOCKET)))
    end
end

_cpuidx(cpuid) = findfirst(isequal(cpuid), unsafe_cpuids_all())

function cpuid2core(cpuid::Integer)
    M = sysinfo().matrix
    row_idx = findfirst(r -> r[IOSID] == cpuid, eachrow(M))
    return M[row_idx, ICORE]
end

# High-level API for direct usage with `pinthreads`
const T_idcs = Union{Colon, AbstractVector{<:Integer}, Integer}

function core(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_core(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end

function numa(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_numa(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end

function socket(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_socket(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end

function node(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_node(; kwargs...)[idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
# function cores(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
#     cpuids = @views interweave(cpuids_per_core(; kwargs...)[idcs]...)
#     shuffle && Random.shuffle!(cpuids)
#     return cpuids
# end

function sockets(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    if idcs isa Integer
        throw(ArgumentError("At least two socket indices needed for round-robin scattering."))
    end
    cpuids = @views interweave(cpuids_per_socket(; kwargs...)[idcs]...)
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end

function numas(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    if idcs isa Integer
        throw(ArgumentError("At least two NUMA domain indices needed for round-robin " *
                            "scattering."))
    end
    cpuids = @views interweave(cpuids_per_numa(; kwargs...)[idcs]...)
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end

end # module
