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

"Check whether hyperthreading is enabled."
hyperthreading_is_enabled() = HYPERTHREADING[]
"Check whether the given cpu thread is a hyperthread (i.e. the second cpu thread associated with a CPU-core)."
ishyperthread(cpuid::Integer) = ISHYPERTHREAD[][cpuid + 1]
"Number of CPU sockets"
nsockets() = NSOCKETS[]
"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available CPU sockets"
cpuids_per_socket() = CPUIDS[]
