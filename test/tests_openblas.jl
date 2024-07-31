include("common.jl")
using Test
using ThreadPinning
using LinearAlgebra: BLAS
BLAS.set_num_threads(4)

function openblas_tests()
    @testset "basics (forwards)" begin
        # not pinned yet
        @test_throws ErrorException openblas_getcpuid(; threadid = 1)
        @test_throws ErrorException openblas_getcpuids()

        c = getcpuid()
        @test isnothing(openblas_pinthread(c; threadid = 1))
        @test openblas_getcpuid(; threadid = 1) == c
        @test openblas_ispinned(; threadid = 1)

        openblas_unpinthread(; threadid = 1)
        @test !openblas_ispinned(; threadid = 1)

        cpuids_allsame = fill(c, BLAS.get_num_threads())
        @test isnothing(openblas_pinthreads(cpuids_allsame))
        @test all(==(c), openblas_getcpuids())
        @test all(i -> openblas_ispinned(; threadid = i), 1:BLAS.get_num_threads())
        @test isnothing(openblas_unpinthreads())
        @test !any(i -> openblas_ispinned(; threadid = i), 1:BLAS.get_num_threads())

        @test isnothing(openblas_printaffinity(; threadid = 1))
        @test isnothing(openblas_printaffinities())
    end
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
