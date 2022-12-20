using Test
using ThreadPinning
using Base.Threads: nthreads
using Random: shuffle

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

ThreadPinning.update_sysinfo!(; fromscratch = true)

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

@testset "Thread Pinning (symbols)" begin
    @testset ":random" begin
        cpuids = Vector{Vector{Int64}}()
        for _ in 1:10
            pinthreads(:random)
            push!(cpuids, getcpuids())
        end
        # Check that at least some of the pinning settings were different
        @test any(x != cpuids[1] for x in cpuids)
    end
    @testset ":current" begin
        pinthreads(:random)
        cpuids_before = getcpuids()
        @test isnothing(pinthreads(:current))
        cpuids_after = getcpuids()
        @test cpuids_before == cpuids_after
    end
    @testset ":firstn" begin
        expected_pinning = cpuids_all()[1:nthreads()]
        # Make sure we have a different pinning to start with
        pinthreads(reverse(expected_pinning))
        @test getcpuids() != expected_pinning
        pinthreads(:firstn)
        @test getcpuids() == expected_pinning
    end
    @testset ":cputhreads" begin
        pinthreads(:random)
        @test isnothing(pinthreads(:cputhreads; nthreads = 2))
        @test getcpuid.(1:2) == cpuids_per_node(; compact = true)[1:2]
    end
    @testset ":cores" begin
        pinthreads(:random)
        @test isnothing(pinthreads(:cores; nthreads = 2))
        @test getcpuid.(1:2) == cpuids_per_node(; compact = false)[1:2]
    end
    @testset ":numa" begin
        pinthreads(:random)
        @test isnothing(pinthreads(:numa; nthreads = 2))
        @test getcpuid.(1:2) == vcat(numa(1, 1:1), numa(2, 1:1))
    end
    @testset ":sockets" begin
        pinthreads(:random)
        @test isnothing(pinthreads(:sockets; nthreads = 2))
        @test getcpuid.(1:2) == vcat(socket(1, 1:1), socket(2, 1:1))
    end
end

@testset "Thread Pinning (logical specification)" begin
    @testset "domains" begin
        pinthreads(:random)
        @test isnothing(pinthreads(core(1, 1:1)))
        @test getcpuid.(1:1) == core(1, 1:1)
        for f in (numa, socket)
            for compact in (false, true)
                pinthreads(:random)
                @test isnothing(pinthreads(f(1, 1:2; compact)))
                @test getcpuid.(1:2) == f(1, 1:2; compact)
            end
        end
        pinthreads(:random)
        @test isnothing(pinthreads(node(1:2)))
        @test getcpuid.(1:2) == node(1:2)
    end

    @testset "concatenation" begin
        pinthreads(:random)
        @test isnothing(pinthreads(core(1, 1:1), core(2, 1:1)))
        @test getcpuid.(1:2) == vcat(core(1, 1:1), core(2, 1:1))
        pinthreads(:random)
        @test isnothing(pinthreads([core(1, 1:1), core(2, 1:1)]))
        @test getcpuid.(1:2) == vcat(core(1, 1:1), core(2, 1:1))
    end
end

@testset "First pin attempt" begin
    @test isnothing(ThreadPinning.forget_pin_attempts())
    @test ThreadPinning.first_pin_attempt()
    pinthreads(:random)
    @test !ThreadPinning.first_pin_attempt()

    # pinthreads with force=false
    ThreadPinning.forget_pin_attempts()
    @test ThreadPinning.first_pin_attempt()
    pinthreads(:compact; force = false)
    @test !ThreadPinning.first_pin_attempt()
    cpuids = getcpuids()
    pinthreads(reverse(cpuids); force = false)
    @test getcpuids() == cpuids
end

@testset "Unpinning" begin
    pinthreads(:compact)
    for tid in 1:nthreads()
        @test count(isone, ThreadPinning.uv_thread_getaffinity(tid)) == 1
    end

    unpinthread(2)
    @test count(isone, ThreadPinning.uv_thread_getaffinity(1)) == 1
    @test count(isone, ThreadPinning.uv_thread_getaffinity(2)) == ncputhreads()

    unpinthreads()
    for tid in 1:nthreads()
        @test count(isone, ThreadPinning.uv_thread_getaffinity(tid)) == ncputhreads()
    end
end

# TODO
# @testset "Environment variables" begin
#     julia = Base.julia_cmd()
#     pkgdir = joinpath(@__DIR__, "..")

#     exec(s; nthreads=ncores()) = run(`$julia --project=$(pkgdir) -t $nthreads -e $s`).exitcode == 0
#     withenv("JULIA_PIN" => "compact") do
#         @test exec(`'using ThreadPinning, Test;
#             @test getcpuids() == filter(!ishyperthread, cpuids_all())[1:Threads.nthreads()]'`)
#     end
#     withenv("JULIA_PIN" => "spread") do
#         @test exec(`'using ThreadPinning, Test;
#         function check_compact_within_socket(cpuids)
#             socket_cpuids = cpuids_per_socket()
#             for s in 1:nsockets()
#                 cpuids_filtered = filter(x -> x in socket_cpuids[s], cpuids)
#                 if cpuids_filtered != socket_cpuids[s][1:length(cpuids_filtered)]
#                     return false
#                 end
#             end
#             return true
#         end
#         @test check_compact_within_socket(getcpuids())'`)
#     end
#     withenv("JULIA_PIN" => "spread", "JULIA_PLACES" => "numa") do
#         @test exec(`'using ThreadPinning, Test;
#         function check_compact_within_numa(cpuids)
#             numa_cpuids = cpuids_per_numa()
#             for s in 1:nnuma()
#                 cpuids_filtered = filter(x -> x in numa_cpuids[s], cpuids)
#                 if cpuids_filtered != numa_cpuids[s][1:length(cpuids_filtered)]
#                     return false
#                 end
#             end
#             return true
#         end
#         @test check_compact_within_numa(getcpuids())'`)
#     end
# end
