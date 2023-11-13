"""
Returns the ID of the CPU thread on which the calling thread is currently running.

See `sched_getcpu` for more information.
"""
getcpuid() = Int(sched_getcpu())

"""
$(SIGNATURES)
Returns the ID of the CPU thread on which the given Julia thread (`threadid`) is currently
running.
"""
getcpuid(threadid::Integer) = fetch(@tspawnat threadid getcpuid())

"""
Returns the IDs of the CPU-threads on which the Julia threads are currently running.

See `getcpuid` for more information.
"""
function getcpuids(; threadpool = :default)::Vector{Int}
    @static if VERSION >= v"1.9-"
        if !(threadpool in (:all, :default, :interactive))
            throw(ArgumentError("Unknown value for `threadpool` keyword argument. " *
                                "Supported values are `:all`, `:default`, and " *
                                "`:interactive`."))
        end
        tids_pool = threadids(threadpool)
        nt = length(tids_pool)
        cpuids = zeros(Int, nt)
        for (i, tid) in pairs(tids_pool)
            cpuids[i] = fetch(@tspawnat tid getcpuid())
        end
    else
        nt = nthreads()
        cpuids = zeros(Int, nt)
        @threads :static for tid in 1:nt
            cpuids[tid] = getcpuid()
        end
    end
    return cpuids
end

"""
Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on which
the calling thread is currently running.
"""
function getnumanode()
    cpuid = getcpuid()
    for (i, cs_numa) in enumerate(unsafe_cpuids_per_numa())
        if cpuid in cs_numa
            return i-1
        end
    end
    return -1
end

"""
$(SIGNATURES)
Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on which
the given Julia thread (`threadid`) is currently running.
"""
getnumanode(threadid::Integer) = fetch(@tspawnat threadid getnumanode())

"""
Returns the ID (starting at zero) of the NUMA nodes corresponding to the CPU threads on which
the Julia threads are currently running.
"""
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
            numanodes[i] = fetch(@tspawnat tid getnumanode())
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

"""
$(SIGNATURES)Print the affinity mask of a Julia thread.
"""
function print_affinity_mask(tid = threadid(); io = getstdout(), kwargs...)
    mask = uv_thread_getaffinity(tid)
    str = _affinity_mask_to_string(mask; kwargs...)
    print(io, rpad("$(tid):", 5))
    println(io, str)
end
"""
$(SIGNATURES)Print the affinity masks of all Julia threads.
"""
function print_affinity_masks(; threadpool = :default, io = getstdout(), kwargs...)
    tids = threadids(threadpool)
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

"""
$(SIGNATURES)Get the affinity mask of the given Julia Thread
"""
get_affinity_mask(tid=threadid()) = uv_thread_getaffinity(tid)[1:ncputhreads()]

"""
$(SIGNATURES)Get the IDs of the CPU-threads associated with the affinity mask of the given Julia Thread
"""
get_cpuids_from_affinity_mask(tid=threadid()) = affinitymask2cpuids(get_affinity_mask(tid))

"Get the CPU-thread IDs associated with the given affinity mask."
function affinitymask2cpuids(mask)
    [unsafe_cpuids_all()[i] for (i, v) in enumerate(mask) if v == 1]
end

"Returns `true` if the thread is pinned, i.e. if it has an affinity mask that comprises a single CPU-thread."
ispinned(tid=threadid()) = count(isequal(1), get_affinity_mask(tid)) == 1

# Unsafe because they directly return the fields instead of copies (be warry when modiying!)
unsafe_cpuids_all() = sysinfo().cpuids
unsafe_cpuids_per_core() = sysinfo().cpuids_cores
unsafe_cpuids_per_numa() = sysinfo().cpuids_numa
unsafe_cpuids_per_socket() = sysinfo().cpuids_sockets
unsafe_cpuids_per_node() = sysinfo().cpuids_node

"Check whether hyperthreading is enabled."
hyperthreading_is_enabled() = sysinfo().hyperthreading
"$(SIGNATURES)Check whether the given CPU-thread is a hyperthread (i.e. the second CPU-thread associated
with a CPU-core)."
ishyperthread(cpuid::Integer) = sysinfo().ishyperthread[_cpuidx(cpuid)]
"Number of CPU-threads"
ncputhreads() = length(cpuids_all())
"Number of cores (i.e. excluding hyperthreads)"
ncores() = sysinfo().ncores
"Number of NUMA nodes"
nnuma() = sysinfo().nnuma
"Number of CPU sockets"
nsockets() = sysinfo().nsockets

"Number of CPU-threads per core"
ncputhreads_per_core() = length.(unsafe_cpuids_per_core())
"Number of CPU-threads per NUMA domain"
ncputhreads_per_numa() = length.(unsafe_cpuids_per_numa())
"Number of CPU-threads per socket"
ncputhreads_per_socket() = length.(unsafe_cpuids_per_socket())

"Number of CPU-cores per NUMA domain"
ncores_per_numa() = count.(!ishyperthread, unsafe_cpuids_per_numa())
"Number of CPU-cores per socket"
ncores_per_socket() = count.(!ishyperthread, unsafe_cpuids_per_socket())

"Returns a `Vector{Int}` which lists all valid CPUIDs. There is no guarantee about the
order except that it is the same as in `lscpu`."
cpuids_all() = deepcopy(unsafe_cpuids_all())
"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
physical cores"
cpuids_per_core() = deepcopy(unsafe_cpuids_per_core())
"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
NUMA domains. Within each memory domain, physical cores come first. Set `compact=true` to
get compact ordering instead.
"""
function cpuids_per_numa(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_numa())
    else
        data = getsortedby([ICPUID, INUMA], (INUMA, ICORE))
        return Vector{Int}[data[data[:, 2] .== n, 1] for n in 1:nnuma()]
    end
end
"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
CPU sockets. Within each socket, physical cores come first. Set `compact=true` to get
compact ordering instead.
"""
function cpuids_per_socket(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_socket())
    else
        data = getsortedby([ICPUID, ISOCKET], (ISOCKET, ICORE))
        return Vector{Int}[data[data[:, 2] .== s, 1] for s in 1:nsockets()]
    end
end
"""
$(SIGNATURES)
Returns a `Vector{Int}` which indicates the CPUIDs associated with the available node.
Physical cores come first. Set `compact=true` to get compact ordering.
"""
function cpuids_per_node(; compact = false)
    if !compact # default
        return deepcopy(unsafe_cpuids_per_node())
    else
        return Vector{Int}(getsortedby(ICPUID, (ICORE, ISMT, ISOCKET)))
    end
end

_cpuidx(cpuid) = findfirst(isequal(cpuid), unsafe_cpuids_all())

function cpuid2core(cpuid::Integer)
    M = sysinfo().matrix
    @static if VERSION < v"1.7"
        row_idx = findfirst(r -> r[ICPUID] == cpuid, collect(eachrow(M)))
    else
        row_idx = findfirst(r -> r[ICPUID] == cpuid, eachrow(M))
    end
    return M[row_idx, ICORE]
end

# High-level API for direct usage with `pinthreads`
const T_idcs = Union{Colon, AbstractVector{<:Integer}, Integer}
"""
$(SIGNATURES)
Represents the CPU ID domain of core `i` (logical index, starts at 1). Uses compact ordering
by default. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function core(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_core(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
"""
$(SIGNATURES)
Represents the CPU ID domain of NUMA/memory domain `i` (logical index, starts at 1). By
default, cores will be used first and hyperthreads will only be used if necessary. Provide
`compact=true` to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function numa(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_numa(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
"""
$(SIGNATURES)
Represents the CPU ID domain of socket `i` (logical index, starts at 1). By default, cores
will be used first and hyperthreads will only be used if necessary. Provide `compact=true`
to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function socket(i::Integer, idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    idcs = idcs isa Integer ? [idcs] : idcs
    cpuids = cpuids_per_socket(; kwargs...)[i][idcs]
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
"""
$(SIGNATURES)
Represents the CPU ID domain of the entire node/system. By default, cores will be used first
and hyperthreads will only be used if necessary. Provide `compact=true` to get compact
ordering instead. Set `shuffle=true` to randomize. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
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
function sockets(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    if idcs isa Integer
        throw(ArgumentError("At least two socket indices needed for round-robin scattering."))
    end
    cpuids = @views interweave(cpuids_per_socket(; kwargs...)[idcs]...)
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
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
function numas(idcs::T_idcs = Colon(); shuffle = false, kwargs...)
    if idcs isa Integer
        throw(ArgumentError("At least two NUMA domain indices needed for round-robin " *
                            "scattering."))
    end
    cpuids = @views interweave(cpuids_per_numa(; kwargs...)[idcs]...)
    shuffle && Random.shuffle!(cpuids)
    return cpuids
end
