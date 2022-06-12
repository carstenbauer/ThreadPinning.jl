using Test
using ThreadPinning

latencies = ThreadPinning.bench_core2core_latency()
@test typeof(latencies) == Matrix{Float64}
@test size(latencies) == (Sys.CPU_THREADS, Sys.CPU_THREADS)
