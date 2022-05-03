using ThreadPinning
using Test
using Base.Threads: @threads, nthreads
using Random: shuffle

nthreads() ≥ 2 ||
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

@testset "ThreadPinning.jl" begin
    @testset "Helper" begin
        @test ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8]) ==
            [1, 5, 2, 6, 3, 7, 4, 8]
        @test ThreadPinning.interweave(1:4, 5:8) == [1, 5, 2, 6, 3, 7, 4, 8]
        @test ThreadPinning.interweave(1:4, 5:8, 9:12) ==
            [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
        # different size inputs
        @test_throws ArgumentError ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8, 9])
    end

    @testset "gather_sysinfo_lscpu (NOCTUA2LOGIN)" begin
        sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_NOCTUA2LOGIN)
        @test typeof(sinfo) == ThreadPinning.SysInfo
        @test sinfo.nsockets == 1
        @test sinfo.nnuma == 4
        @test sinfo.hyperthreading == true
        @test length(sinfo.cpuids_sockets) == 1
        @test sinfo.cpuids_sockets[1] == 0:127
        @test length(sinfo.cpuids_numa) == 4
        @test sinfo.cpuids_numa[1] == vcat(0:15, 64:79)
        @test sinfo.cpuids_numa[2] == vcat(16:31, 80:95)
        @test sinfo.cpuids_numa[3] == vcat(32:47, 96:111)
        @test sinfo.cpuids_numa[4] == vcat(48:63, 112:127)
        @test sinfo.ishyperthread == vcat(falses(64), trues(64))
    end

    @testset "gather_sysinfo_lscpu (FUGAKU)" begin
        sinfo = ThreadPinning.gather_sysinfo_lscpu(ThreadPinning.lscpu_FUGAKU)
        @test typeof(sinfo) == ThreadPinning.SysInfo
        @test sinfo.nsockets == 1
        @test sinfo.nnuma == 6
        @test sinfo.hyperthreading == false
        @test length(sinfo.cpuids_sockets) == 1
        @test sinfo.cpuids_sockets[1] == vcat([0, 1], 12:59)
        @test length(sinfo.cpuids_numa) == 6
        @test sinfo.cpuids_numa[1] == [0]
        @test sinfo.cpuids_numa[2] == [1]
        @test sinfo.cpuids_numa[3] == 12:23
        @test sinfo.cpuids_numa[4] == 24:35
        @test sinfo.cpuids_numa[5] == 36:47
        @test sinfo.cpuids_numa[6] == 48:59
        @test sinfo.ishyperthread == falses(50)
    end

    @testset "Querying" begin
        pinthreads(:random)
        @test typeof(getcpuid()) == Int
        @test typeof(getcpuids()) == Vector{Int}
        @test getcpuids() == getcpuid.(1:Threads.nthreads())
        @test typeof(nsockets()) == Int
        @test nsockets() >= 1
        @test typeof(hyperthreading_is_enabled()) == Bool
        @test typeof(cpuids_per_socket()) == Vector{Vector{Int}}
        @test ishyperthread(0) == false
    end

    @testset "threadinfo()" begin
        @test isnothing(threadinfo())
        @test isnothing(threadinfo(; groupby=:numa))
    end

    @testset "Thread Pining (explicit)" begin
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
        for cpuid in rand(0:(Sys.CPU_THREADS - 1), 5)
            @test isnothing(pinthread(rand_thread, cpuid))
            @test getcpuid(rand_thread) == cpuid
        end
    end

    @testset "Thread Pinning (compact)" begin
        @assert getcpuids() != 0:(nthreads() - 1)
        @test isnothing(pinthreads(:compact; nthreads=2))
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

    @testset "Core2CoreLatency" begin
        latencies = ThreadPinning.bench_core2core_latency()
        @test typeof(latencies) == Matrix{Float64}
        @test size(latencies) == (Sys.CPU_THREADS, Sys.CPU_THREADS)
    end
end
