"""
Returns the ID of the CPU on which the calling thread
is currently executing.
"""
function getcpuid()
    @static if Sys.iswindows()
        return Int(Windows.get_current_processor_number())
    else
        return Int(sched_getcpu())
    end
end

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
cpuids_per_socket() = sysinfo().cpuids_sockets
"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available NUMA nodes"
cpuids_per_numa() = sysinfo().cpuids_numa
"Returns a `Vector{Int}` which lists all valid CPUIDs"
cpuids_all() = sysinfo().cpuids

_cpuidx(cpuid) = findfirst(isequal(cpuid), cpuids_all())
