include("common.jl")
using Test
using ThreadPinning
using LinearAlgebra: BLAS
BLAS.set_num_threads(4)

const randtid = rand(1:BLAS.get_num_threads())

function openblas_tests()
    @testset "openblas initial" begin
        # not pinned yet
        @test_throws ErrorException openblas_getcpuid(; threadid = randtid)
        @test_throws ErrorException openblas_getcpuids()
    end

    @testset "openblas pinning: explicit" begin
        cpuid1, cpuid2 = get_two_cpuids()
        @test isnothing(openblas_pinthread(cpuid1; threadid = randtid))
        @test openblas_getcpuid(; threadid = randtid) == cpuid1
        @test isnothing(openblas_pinthreads([cpuid1, cpuid2]))
        @test openblas_getcpuid(; threadid = 1) == cpuid1
        @test openblas_getcpuid(; threadid = 2) == cpuid2
        @test isnothing(openblas_pinthreads([cpuid2, cpuid1]))
        @test openblas_getcpuid(; threadid = 1) == cpuid2
        @test openblas_getcpuid(; threadid = 2) == cpuid1

        for cpuid in (cpuid1, cpuid2)
            @test isnothing(openblas_pinthread(cpuid; threadid = randtid))
            @test openblas_getcpuid(; threadid = randtid) == cpuid
        end
    end

    @testset "openblas pinning: symbols" begin
        @testset ":random" begin
            @test isnothing(openblas_pinthreads(:random))
            # can we test more here?
        end
        @testset ":firstn" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(:firstn))
            @test openblas_getcpuids() ==
                  sort!(ThreadPinning.cpuids())[1:BLAS.get_num_threads()]
        end
        @testset ":cputhreads" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(:cputhreads; nthreads = 2))
            @test openblas_getcpuids()[1:2] == node(1:2; compact = true)
        end
        @testset ":cores" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(:cores; nthreads = 2))
            @test openblas_getcpuids()[1:2] == node(1:2; compact = false)
        end
        @testset ":numa" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(:numa; nthreads = 2))
            if nnuma() > 1
                @test openblas_getcpuids()[1:2] == vcat(numa(1, 1), numa(2, 1))
            else
                @test openblas_getcpuids()[1:2] == numa(1, 1:2)
            end
        end
        @testset ":sockets" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(:sockets; nthreads = 2))
            if nsockets() > 1
                @test openblas_getcpuids()[1:2] == vcat(socket(1, 1), socket(2, 1))
            else
                @test openblas_getcpuids()[1:2] == socket(1, 1:2)
            end
        end
    end

    @testset "openblas pinning: logical" begin
        @testset "domains" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(core(1, 1:1)))
            @test openblas_getcpuids()[1:1] == core(1, 1:1)
            for f in (socket,)
                for compact in (false, true)
                    openblas_pinthreads(:random)
                    @test isnothing(openblas_pinthreads(f(1, 1:2; compact)))
                    @test openblas_getcpuids()[1:2] == f(1, 1:2; compact)
                end
            end
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(node(1:2)))
            @test openblas_getcpuids()[1:2] == node(1:2)
        end

        @testset "concatenation" begin
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads(core(1, 1:1), core(2, 1:1)))
            @test openblas_getcpuids()[1:2] == vcat(core(1, 1:1), core(2, 1:1))
            openblas_pinthreads(:random)
            @test isnothing(openblas_pinthreads([core(1, 1:1), core(2, 1:1)]))
            @test openblas_getcpuids()[1:2] == vcat(core(1, 1:1), core(2, 1:1))
        end
    end

    @testset "openblas unpinning" begin
        openblas_pinthreads(:random)
        @test all(i -> openblas_ispinned(; threadid = i), 1:BLAS.get_num_threads())

        @test isnothing(openblas_unpinthread(; threadid = randtid))
        @test !openblas_ispinned(; threadid = randtid)

        openblas_unpinthreads()
        @test !any(i -> openblas_ispinned(; threadid = i), 1:BLAS.get_num_threads())
    end

    @testset "openblas setaffinity" begin
        mask = openblas_getaffinity(; threadid = randtid)
        @test isnothing(openblas_setaffinity(mask; threadid = randtid))

        cpuid1, cpuid2 = get_two_cpuids()
        @test isnothing(openblas_setaffinity_cpuids([cpuid2, cpuid1]; threadid = randtid))
    end
end

@testset "HostSystem" begin
    openblas_tests()
end

@testset "TestSystems" begin
    for name in ThreadPinning.Faking.systems()
        println("")
        @warn("\nTestSystem: $name\n")
        ThreadPinning.Faking.with(name) do
            @testset "$name" begin
                openblas_tests()
            end
        end
    end
    println()
end
