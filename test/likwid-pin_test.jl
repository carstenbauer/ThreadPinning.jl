using ThreadPinning
using Test
using Statistics

Threads.nthreads() ≥ 4 ||
    error("Need at least 4 Julia threads! Forgot to set `JULIA_NUM_THREADS`?")

# lp_expression = "E:N:4:2:4" # E:<domain>:<nthreads>(:<chunk size>:<stride>). 2 threads pinned two first two cpu threads (logical, incl. SMT) and 2 threads pinned to 5th and 6th cpu threads.
# lp_scatter_policy = "M:scatter" # scatter threads among all NUMA domains, phyical cores come first
# lp_domains = "S0:0-1@S1:0-1" # 2 threads per socket

@testset "likwid-pin: explicit" begin
    # physical / OS order
    pinthreads(:random)
    lp_explicit = "0,2,1,3"
    pinthreads(lp_explicit)
    @test getcpuids()[1:4] == [0, 2, 1, 3]

    pinthreads(:random)
    lp_explicit_range = "2-5"
    pinthreads(lp_explicit_range)
    @test getcpuids()[1:4] == 2:5

    pinthreads(:random)
    lp_explicit_ranges = "2-3,5-6"
    pinthreads(lp_explicit_ranges)
    @test getcpuids()[1:4] == vcat(2:3, 5:6)
end

@testset "likwid-pin: domain-based" begin
    # logical order, physical cores first(!), starts with 0(!)
    @testset "domain:explicit" begin
        for lpstr in ("N:0-3", "N:0,1,2,3", "S0:0-3", "S0:0,1,2,3", "M0:0-3", "M0:0,1,2,3") # 4 threads to first 4 cores in node
            pinthreads(:random)
            pinthreads(lpstr)
            @test getcpuids()[1:4] == cpuids_per_node()[1:4]
        end
        if nsockets() > 1
            lpstr = "S1:0-3"
            pinthreads(:random)
            pinthreads(lpstr)
            @test getcpuids()[1:4] == cpuids_per_socket()[2][1:4]
        end
        if nnuma() > 1
            lpstr = "M1:0,1,2,3"
            pinthreads(:random)
            pinthreads(lpstr)
            @test getcpuids()[1:4] == cpuids_per_numa()[2][1:4]
        end
    end

    @testset "domain:scatter[:numthreads]" begin
        for lpstr in ("S0:scatter", "M0:scatter", "N:scatter") # 4 threads to first 4 cores in node
            pinthreads(:random)
            pinthreads(lpstr)
            @test getcpuids()[1:4] == cpuids_per_node()[1:4]
        end

        let lpstr = "S:scatter"
            pinthreads(:random)
            pinthreads(lpstr)
            num_threads = 4
            cpuids_socket = cpuids_per_socket()
            cpuids = zeros(Int, num_threads)
            for i in 1:num_threads
                c, s = divrem(i - 1, nsockets()) .+ (1, 1)
                cpuids[i] = cpuids_socket[s][c]
            end
            @test getcpuids()[1:num_threads] == cpuids

            lpstr_nthreads = "S:scatter:2"
            pinthreads(:random)
            pinthreads(lpstr_nthreads)
            @test getcpuids()[1:2] == cpuids[1:2]
            @test getcpuids()[3:4] != cpuids[3:4]
        end

        let lpstr = "M:scatter"
            pinthreads(:random)
            pinthreads(lpstr)
            num_threads = 4
            cpuids_numa = cpuids_per_numa()
            cpuids = zeros(Int, num_threads)
            for i in 1:num_threads
                c, n = divrem(i - 1, nnuma()) .+ (1, 1)
                cpuids[i] = cpuids_numa[n][c]
            end
            @test getcpuids()[1:num_threads] == cpuids

            lpstr_nthreads = "M:scatter:2"
            pinthreads(:random)
            pinthreads(lpstr_nthreads)
            @test getcpuids()[1:2] == cpuids[1:2]
            @test getcpuids()[3:4] != cpuids[3:4]
        end
    end
end
