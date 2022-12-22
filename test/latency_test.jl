using ThreadPinning
import ThreadPinning: bench_core2core_latency
using Test

@testset "bench_core2core_latency" begin
    @test bench_core2core_latency(0:3; nbench = 1) isa Matrix{Float64}
end
