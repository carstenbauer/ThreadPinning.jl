include("common.jl")
using ThreadPinning
using LinearAlgebra
using Test

@testset "openblas querying" begin
    @testset "utility" begin @test ThreadPinning.openblas_nthreads() ==
                                   BLAS.get_num_threads() end

    @static if VERSION >= v"1.9-"
        @testset "affinity mask" begin
            @test isnothing(ThreadPinning.openblas_print_affinity_masks())
            # The following should error because we haven't pinned yet.
            # Thus, the affinity masks are all ones.
            # @test_throws ErrorException ThreadPinning.openblas_getcpuid(1)
            @test_throws ErrorException ThreadPinning.openblas_getcpuids()
        end
    end
end

@testset "openblas pinning" begin
    nblas = ThreadPinning.openblas_nthreads()
    all_cpuids = cpuids_per_node()
    for cpuids in (all_cpuids[1:nblas], all_cpuids[nblas:-1:1])
        @test isnothing(ThreadPinning.openblas_pinthreads(cpuids))
        @test isnothing(ThreadPinning.openblas_pinthreads(cpuids;
                                                          nthreads = nblas))
        @static if VERSION >= v"1.9-"
            @test ThreadPinning.openblas_getcpuids() == cpuids
        end
    end
end
