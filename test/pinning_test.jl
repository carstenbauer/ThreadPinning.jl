using Test
using ThreadPinning
using Base.Threads: nthreads
using Random: shuffle

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

function check_compact_within_socket(cpuids)
    socket_cpuids = cpuids_per_socket()
    for s in 1:nsockets()
        cpuids_filtered = filter(x -> x in socket_cpuids[s], cpuids)
        if cpuids_filtered != socket_cpuids[s][1:length(cpuids_filtered)]
            return false
        end
    end
    return true
end

function check_compact_within_numa(cpuids)
    numa_cpuids = cpuids_per_numa()
    for s in 1:nnuma()
        cpuids_filtered = filter(x -> x in numa_cpuids[s], cpuids)
        if cpuids_filtered != numa_cpuids[s][1:length(cpuids_filtered)]
            return false
        end
    end
    return true
end

@testset "Thread Pinning (explicit)" begin
    cpuid_before = getcpuid()
    cpuid_new = cpuid_before != 1 ? 1 : 0
    @test pinthread(cpuid_new)
    @test getcpuid() == cpuid_new
    cpuids_new = shuffle(0:(nthreads() - 1))
    @test isnothing(pinthreads(cpuids_new))
    @test getcpuids() == cpuids_new
    cpuids_new = reverse(0:(nthreads() - 1))
    @test isnothing(pinthreads(cpuids_new))
    @test getcpuids() == cpuids_new

    rand_thread = rand(1:Threads.nthreads())
    for cpuid in rand(cpuids_all(), 5)
        @test isnothing(pinthread(rand_thread, cpuid))
        @test getcpuid(rand_thread) == cpuid
    end
end

@testset "Thread Pinning (compact)" begin
    @assert getcpuids() != 0:(nthreads() - 1)
    @test isnothing(pinthreads(:compact; nthreads = 2))
    @test getcpuids()[1:2] == 0:1
    @test isnothing(pinthreads(:compact))
    @test getcpuids() == 0:(nthreads() - 1)
end

@testset "Thread Pinning (scatter)" begin
    @test isnothing(pinthreads(:scatter))
    cpuids_after = getcpuids()
    @test check_compact_within_socket(cpuids_after)
end

@testset "Thread Pinning (numa)" begin
    @test isnothing(pinthreads(:numa))
    cpuids_after = getcpuids()
    @test check_compact_within_numa(cpuids_after)
end
