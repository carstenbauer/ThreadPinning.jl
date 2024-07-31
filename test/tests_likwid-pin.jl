include("common.jl")
using ThreadPinning
using Test
using Statistics
import SysInfo

Threads.nthreads() ≥ 4 ||
    error("Need at least 4 Julia threads! Forgot to set `JULIA_NUM_THREADS`?")

function likwidpin_tests()
    @testset "likwid-pin: explicit" begin
        # physical / OS order
        lp_explicit = "0,2,1,3"
        pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lp_explicit)
        @test pinthreads_cpuids[1:4] == [0, 2, 1, 3]

        lp_explicit_range = "2-5"
        pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lp_explicit_range)
        @test pinthreads_cpuids[1:4] == 2:5

        lp_explicit_ranges = "2-3,5-6"
        pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lp_explicit_ranges)
        @test pinthreads_cpuids[1:4] == vcat(2:3, 5:6)

        @testset "Errors" begin
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("0,-1,2")
            # @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("0,10,12345")
        end
    end

    @testset "likwid-pin: domain-based" begin
        # logical order, physical cores first(!), starts with 0(!)
        @testset "domain:explicit" begin
            if SysInfo.ncputhreads_within_numa(1) >= 4
                for lpstr in ("N:0-3", "N:0,1,2,3", "S0:0-3", "S0:0,1,2,3", "M0:0-3",
                    "M0:0,1,2,3") # 4 threads to first 4 cores in node
                    pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                    @test pinthreads_cpuids[1:4] == node(1:4)
                end
            end
            if nsockets() > 1 && SysInfo.ncputhreads_within_socket(2) >= 4
                lpstr = "S1:0-3"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == socket(2, 1:4)
            end
            if nnuma() > 1 && SysInfo.ncputhreads_within_numa(2) >= 4
                lpstr = "M1:0,1,2,3"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == numa(2, 1:4)
            end
        end

        @testset "domain:scatter[:numthreads]" begin
            if SysInfo.ncputhreads_within_numa(1) >= 4
                for lpstr in ("S0:scatter", "M0:scatter", "N:scatter")
                    pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                    @test pinthreads_cpuids[1:4] == node(1:4)
                end
            end

            let lpstr = "S:scatter"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                num_threads = 4
                cpuids = zeros(Int, num_threads)
                for i in 1:num_threads
                    c, s = divrem(i - 1, nsockets()) .+ (1, 1)
                    cpuids[i] = only(socket(s, c))
                end
                @test pinthreads_cpuids[1:num_threads] == cpuids

                lpstr_nthreads = "S:scatter:2"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr_nthreads)
                @test pinthreads_cpuids[1:2] == cpuids[1:2]
            end

            let lpstr = "M:scatter"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                num_threads = 4
                cpuids = zeros(Int, num_threads)
                for i in 1:num_threads
                    c, n = divrem(i - 1, nnuma()) .+ (1, 1)
                    cpuids[i] = only(numa(n, c))
                end
                @test pinthreads_cpuids[1:num_threads] == cpuids

                lpstr_nthreads = "M:scatter:2"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr_nthreads)
                @test pinthreads_cpuids[1:2] == cpuids[1:2]
                # @test pinthreads_cpuids[3:4] != cpuids[3:4]
            end
        end

        @testset "Errors" begin
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("N:whatever")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("X:scatter")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("N:-1")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("N:0,10,12345")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("N:0-12345")
        end
    end

    @testset "likwid-pin: expression" begin
        if SysInfo.ncputhreads_within_numa(1) >= 4
            @testset "E:domain:numthreads" begin
                for lpstr in ("E:N:3", "E:S0:3", "E:M0:3")
                    pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                    @test pinthreads_cpuids[1:3] == node(1:3; compact = true)
                end
            end
        end

        @testset "E:domain:numthreads:chunk_size:stride" begin
            # TODO
            # lp_expression = "E:N:4:2:4" # E:<domain>:<nthreads>(:<chunk size>:<stride>). 2 threads pinned two first two CPU-threads (logical, incl. SMT) and 2 threads pinned to 5th and 6th CPU-threads.
        end

        @testset "Errors" begin
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("E:N:12345")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("E:X:3")
            @test_throws ArgumentError ThreadPinning.LIKWID.likwidpin_to_cpuids("E:N:3:4:5:10")
        end
    end

    @testset "likwidpin: @ concatenation" begin
        if SysInfo.ncputhreads_within_socket(1) >= 4
            let lpstr = "S0:0-1@S0:2-3"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == socket(1, 1:4)
            end
            let lpstr = "S0:0@S0:1@S0:2@S0:3"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == socket(1, 1:4)
            end
        end
        if nsockets() > 1 && SysInfo.ncputhreads_within_socket(1) >= 2 &&
           SysInfo.ncputhreads_within_socket(2) >= 2
            let lpstr = "S0:0-1@S1:1-2" # 2 threads per socket
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == vcat(socket(1, 1:2), socket(2, 2:3))
            end
        end
        if nnuma() > 1 && SysInfo.ncputhreads_within_numa(1) >= 2 &&
           SysInfo.ncputhreads_within_numa(2) >= 2
            let lpstr = "M0:0-1@M1:1-2" # 2 threads per memory domain
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == vcat(numa(1, 1:2), numa(2, 2:3))
            end
        end
        if nnuma() > 1 && nsockets() > 1 && SysInfo.ncputhreads_within_numa(1) >= 2 &&
           SysInfo.ncputhreads_within_socket(2) >= 2
            let lpstr = "M0:0-1@S1:1-2"
                pinthreads_cpuids = ThreadPinning.LIKWID.likwidpin_to_cpuids(lpstr)
                @test pinthreads_cpuids[1:4] == vcat(numa(1, 1:2), socket(2, 2:3))
            end
        end
    end
end

@testset "TestSystems" begin
    for name in ThreadPinning.Faking.systems()
        println("")
        @warn("\nTestSystem: $name\n")
        ThreadPinning.Faking.with(name) do
            @testset "$name" begin
                likwidpin_tests()
            end
        end
    end
    println()
end
