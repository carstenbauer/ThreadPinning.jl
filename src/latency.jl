include("Core2CoreLatency/Core2CoreLatency.jl")
using .Core2CoreLatency

"""
    bench_core2core_latency([cpuids = 0:Sys.CPU_THREADS-1; nbench = 5, nsamples::Integer = 100, mode::Symbol = :min])
A tool for measuring core-to-core latency (i.e. inter-core latency) in nanoseconds.

The measured latencies correspond to a full roundtrip between two cores. Divide them by two to obtain an estimate for the time needed to fetch data from another core.

**Important:** At least two Julia threads are required (`julia -t2`)!

**Refs:** Largely inspired by [rigtorp/c2clat](https://github.com/rigtorp/c2clat) and [ajakubek/core-latency](https://github.com/ajakubek/core-latency).
"""
function bench_core2core_latency(cpuids = 0:(Sys.CPU_THREADS - 1); nbench = 5, kwargs...)
    # check validity of cpuids input
    for c in cpuids
        if c < 0 || c > Sys.CPU_THREADS
            @error("CPU IDs must all be non-negative and ≤ Sys.CPU_THREADS.")
        end
    end
    # backup current thread affinity
    pinning_before = getcpuids()
    # run benchmarks
    ncpuids = length(cpuids)
    latencies = zeros(ncpuids, ncpuids)
    for b in 1:nbench
        for (j, cpu2) in pairs(cpuids)
            for (i, cpu1) in pairs(cpuids)
                @inbounds latencies[i, j] += Core2CoreLatency.run_bench(cpu1, cpu2;
                                                                        kwargs...)
            end
        end
    end
    latencies ./= nbench
    # restore previous thread affinity
    pinthreads(pinning_before)
    return latencies
end
