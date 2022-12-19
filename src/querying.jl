"""
Returns the ID of the CPU on which the calling thread
is currently executing.

See `sched_getcpu` for more information.
"""
getcpuid() = Int(sched_getcpu())

"""
Returns the ID of the CPU on which the given Julia thread
(`threadid`) is currently executing.
"""
getcpuid(threadid::Integer) = fetch(@tspawnat threadid getcpuid())

"""
Returns the ID of the CPUs on which the Julia threads
are currently running.

See `getcpuid` for more information.
"""
function getcpuids()
    nt = nthreads()
    cpuids = zeros(Int, nt)
    @threads :static for tid in 1:nt
        cpuids[tid] = getcpuid()
    end
    return cpuids
end

"""
Print the affinity masks of all Julia threads.
"""
function print_affinity_masks(; kwargs...)
    for tid in 1:nthreads()
        mask = uv_thread_getaffinity(tid)
        str = _affinity_mask_to_string(mask; kwargs...)
        print(rpad("$(tid):", 5))
        println(str)
    end
    return nothing
end
function _affinity_mask_to_string(mask; groupby = :sockets)
    bitstr = join(mask)[1:ncputhreads()]
    if groupby == :numa
        cpuids_per_X = cpuids_per_numa
        nX = nnuma
    else
        cpuids_per_X = cpuids_per_socket
        nX = nsockets
    end
    str = "|"
    for s in 1:nX()
        str = string(str, bitstr[cpuids_per_X()[s] .+ 1], "|")
    end
    return str
end

"""
Get information about the system like how many sockets or NUMA nodes it has, whether hyperthreading is enabled, etc.
"""
function sysinfo()
    return SYSINFO[]
end

# Unsafe because they directly return the fields instead of copies (be warry when modiying!)
unsafe_cpuids_all() = sysinfo().cpuids
unsafe_cpuids_per_core() = sysinfo().cpuids_cores
unsafe_cpuids_per_numa() = sysinfo().cpuids_numa
unsafe_cpuids_per_socket() = sysinfo().cpuids_sockets
unsafe_cpuids_per_node() = sysinfo().cpuids_node

"Check whether hyperthreading is enabled."
hyperthreading_is_enabled() = sysinfo().hyperthreading
"Check whether the given cpu thread is a hyperthread (i.e. the second cpu thread associated with a CPU-core)."
ishyperthread(cpuid::Integer) = sysinfo().ishyperthread[_cpuidx(cpuid)]
"Number of CPU threads"
ncputhreads() = length(cpuids_all())
"Number of cores (i.e. excluding hyperthreads)"
ncores() = sysinfo().ncores
"Number of NUMA nodes"
nnuma() = sysinfo().nnuma
"Number of CPU sockets"
nsockets() = sysinfo().nsockets

"Number of CPU threads per core"
ncputhreads_per_core() = length.(unsafe_cpuids_per_core())
"Number of CPU threads per NUMA domain"
ncputhreads_per_numa() = length.(unsafe_cpuids_per_numa())
"Number of CPU threads per socket"
ncputhreads_per_socket() = length.(unsafe_cpuids_per_socket())

"Number of CPU cores per NUMA domain"
ncores_per_numa() = count.(!ishyperthread, unsafe_cpuids_per_numa())
"Number of CPU cores per socket"
ncores_per_socket() = count.(!ishyperthread, unsafe_cpuids_per_socket())

"Returns a `Vector{Int}` which lists all valid CPUIDs. There is no guarantee about the
order except that it is the same as in `lscpu`."
cpuids_all() = deepcopy(unsafe_cpuids_all())
"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available physical cores"
cpuids_per_core() = deepcopy(unsafe_cpuids_per_core())
"""
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
