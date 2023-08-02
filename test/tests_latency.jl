include("common.jl")
using ThreadPinning
import ThreadPinning: bench_core2core_latency
using Test

ThreadPinning.update_sysinfo!(; fromscratch = true)

@testset "bench_core2core_latency" begin
    cores = node(1:4)
    @test bench_core2core_latency(cores; nbench = 1) isa Matrix{Float64}
end
