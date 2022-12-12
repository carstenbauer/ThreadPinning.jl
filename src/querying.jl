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
function _affinity_mask_to_string(mask; groupby=:sockets)
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
        str = string(str, bitstr[cpuids_per_X()[s].+1], "|")
    end
    return str
end

"""
Get information about the system like how many sockets or NUMA nodes it has, whether hyperthreading is enabled, etc.
"""
function sysinfo()
    return SYSINFO[]
end
"Check whether hyperthreading is enabled."
hyperthreading_is_enabled() = sysinfo().hyperthreading
"Check whether the given cpu thread is a hyperthread (i.e. the second cpu thread associated with a CPU-core)."
ishyperthread(cpuid::Integer) = sysinfo().ishyperthread[_cpuidx(cpuid)]
"Number of CPU sockets"
nsockets() = sysinfo().nsockets
"Number of NUMA nodes"
nnuma() = sysinfo().nnuma
"Number of CPU threads"
ncputhreads() = length(cpuids_all())
"Number of CPU threads per NUMA domain"
ncputhreads_per_numa() = length.(cpuids_per_numa())
"Number of CPU threads per socket"
ncputhreads_per_socket() = length.(cpuids_per_socket())
"Number of cores (i.e. excluding hyperthreads)"
ncores() = count(!ishyperthread, cpuids_all())
"Number of CPU cores per NUMA domain"
ncores_per_numa() = count.(!ishyperthread, cpuids_per_numa())
"Number of CPU cores per socket"
ncores_per_socket() = count.(!ishyperthread, cpuids_per_socket())

"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available CPU sockets"
cpuids_per_socket() = copy(sysinfo().cpuids_sockets)
"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available NUMA nodes"
cpuids_per_numa() = copy(sysinfo().cpuids_numa)
"Returns a `Vector{Int}` which lists all valid CPUIDs"
cpuids_all() = copy(sysinfo().cpuids)

_cpuidx(cpuid) = findfirst(isequal(cpuid), cpuids_all())
