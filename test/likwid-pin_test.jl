using ThreadPinning
using Test
using Statistics

Threads.nthreads() ≥ 4 ||
    error("Need at least 4 Julia threads! Forgot to set `JULIA_NUM_THREADS`?")

@testset "likwid-pin: explicit" begin
    # physical / OS order
    pinthreads(:random)
    lp_explicit = "0,2,1,3"
    pinthreads_likwidpin(lp_explicit)
    @test getcpuids()[1:4] == [0, 2, 1, 3]

    pinthreads(:random)
    lp_explicit_range = "2-5"
    pinthreads_likwidpin(lp_explicit_range)
    @test getcpuids()[1:4] == 2:5

    pinthreads(:random)
    lp_explicit_ranges = "2-3,5-6"
    pinthreads_likwidpin(lp_explicit_ranges)
    @test getcpuids()[1:4] == vcat(2:3, 5:6)

    @testset "Errors" begin
        @test_throws ArgumentError pinthreads_likwidpin("0,-1,2")
        @test_throws ArgumentError pinthreads_likwidpin("0,10,12345")
    end
end

@testset "likwid-pin: domain-based" begin
    # logical order, physical cores first(!), starts with 0(!)
    @testset "domain:explicit" begin
        for lpstr in ("N:0-3", "N:0,1,2,3", "S0:0-3", "S0:0,1,2,3", "M0:0-3", "M0:0,1,2,3") # 4 threads to first 4 cores in node
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            @test getcpuids()[1:4] == cpuids_per_node()[1:4]
        end
        if nsockets() > 1
            lpstr = "S1:0-3"
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            @test getcpuids()[1:4] == cpuids_per_socket()[2][1:4]
        end
        if nnuma() > 1
            lpstr = "M1:0,1,2,3"
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            @test getcpuids()[1:4] == cpuids_per_numa()[2][1:4]
        end
    end

    @testset "domain:scatter[:numthreads]" begin
        for lpstr in ("S0:scatter", "M0:scatter", "N:scatter")
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            @test getcpuids()[1:4] == cpuids_per_node()[1:4]
        end

        let lpstr = "S:scatter"
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
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
            pinthreads_likwidpin(lpstr_nthreads)
            @test getcpuids()[1:2] == cpuids[1:2]
            @test getcpuids()[3:4] != cpuids[3:4]
        end

        let lpstr = "M:scatter"
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
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
            pinthreads_likwidpin(lpstr_nthreads)
            @test getcpuids()[1:2] == cpuids[1:2]
            # @test getcpuids()[3:4] != cpuids[3:4]
        end
    end

    @testset "Errors" begin
        @test_throws ArgumentError pinthreads_likwidpin("N:whatever")
        @test_throws ArgumentError pinthreads_likwidpin("X:scatter")
        @test_throws ArgumentError pinthreads_likwidpin("N:-1")
        @test_throws ArgumentError pinthreads_likwidpin("N:0,10,12345")
        @test_throws ArgumentError pinthreads_likwidpin("N:0-12345")
    end
end

@testset "likwid-pin: expression" begin
    @testset "E:domain:numthreads" begin for lpstr in ("E:N:3", "E:S0:3", "E:M0:3")
        pinthreads(:random)
        pinthreads_likwidpin(lpstr)
        @test getcpuids()[1:3] == cpuids_per_node(; compact = true)[1:3]
    end end

    @testset "E:domain:numthreads:chunk_size:stride" begin
        # TODO
        # lp_expression = "E:N:4:2:4" # E:<domain>:<nthreads>(:<chunk size>:<stride>). 2 threads pinned two first two cpu threads (logical, incl. SMT) and 2 threads pinned to 5th and 6th cpu threads.
    end

    @testset "Errors" begin
        @test_throws ArgumentError pinthreads_likwidpin("E:N:12345")
        @test_throws ArgumentError pinthreads_likwidpin("E:X:3")
        @test_throws ArgumentError pinthreads_likwidpin("E:N:3:4:5:10")
    end
end

@testset "likwidpin: @ concatenation" begin
    let lpstr = "S0:0-1@S0:2-3"
        pinthreads(:random)
        pinthreads_likwidpin(lpstr)
        cs = cpuids_per_socket()
        @test getcpuids()[1:4] == cs[1][1:4]
    end
    let lpstr = "S0:0@S0:1@S0:2@S0:3"
        pinthreads(:random)
        pinthreads_likwidpin(lpstr)
        cs = cpuids_per_socket()
        @test getcpuids()[1:4] == cs[1][1:4]
    end
    if nsockets() > 1
        let lpstr = "S0:0-1@S1:1-2" # 2 threads per socket
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            cs = cpuids_per_socket()
            @test getcpuids()[1:4] == vcat(cs[1][1:2], cs[2][2:3])
        end
    end
    if nnuma() > 1
        let lpstr = "M0:0-1@M1:1-2" # 2 threads per memory domain
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            cn = cpuids_per_numa()
            @test getcpuids()[1:4] == vcat(cn[1][1:2], cn[2][2:3])
        end
    end
    if nnuma() > 1 && nsockets() > 1
        let lpstr = "M0:0-1@S1:1-2"
            pinthreads(:random)
            pinthreads_likwidpin(lpstr)
            cs = cpuids_per_socket()
            cn = cpuids_per_numa()
            @test getcpuids()[1:4] == vcat(cn[1][1:2], cs[2][2:3])
        end
    end
end
