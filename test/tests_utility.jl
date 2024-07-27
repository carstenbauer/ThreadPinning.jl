include("common.jl")
using ThreadPinning
using LinearAlgebra
using Test

Utility = ThreadPinning.Utility

@testset "interweave" begin
    @test Utility.interweave([1, 2, 3, 4], [5, 6, 7, 8]) ==
          [1, 5, 2, 6, 3, 7, 4, 8]
    @test Utility.interweave(1:4, 5:8) == [1, 5, 2, 6, 3, 7, 4, 8]
    @test Utility.interweave(1:4, 5:8, 9:12) ==
          [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
    # different size inputs
    @test_throws ArgumentError Utility.interweave([1, 2, 3, 4], [5, 6, 7, 8, 9])

    @test Utility.interweave_binary([1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12]) ==
          [1, 9, 2, 10, 3, 11, 4, 12, 5, 6, 7, 8]
    @test Utility.interweave_binary([1, 2, 3, 4], [5, 6, 7, 8, 9, 10, 11, 12]) ==
          [1, 5, 2, 6, 3, 7, 4, 8, 9, 10, 11, 12]
end

@testset "threadids" begin
    @test ThreadPinning.threadids(; threadpool = :all) ==
          1:(Threads.nthreads(:default) + Threads.nthreads(:interactive))
    @test length(ThreadPinning.threadids(; threadpool = :default)) ==
          Threads.nthreads(:default)
    @test length(ThreadPinning.threadids(; threadpool = :interactive)) ==
          Threads.nthreads(:interactive)
end

@testset "spawnat" begin
    ntdefault = Threads.nthreads(:default)
    ntinteractive = Threads.nthreads(:interactive)
    for tid in ThreadPinning.threadids(; threadpool = :all)
        @test fetch(@spawnat tid Threads.threadid()) == tid
    end
    for tid in ThreadPinning.threadids(; threadpool = :default)
        @test fetch(@spawnat tid Threads.threadpool()) == :default
    end
    for tid in ThreadPinning.threadids(; threadpool = :interactive)
        @test fetch(@spawnat tid Threads.threadpool()) == :interactive
    end
end

@testset "BLAS utility" begin
    @test contains(Utility.BLAS_lib(), "openblas")
    @test Utility.nblasthreads() == BLAS.get_num_threads()
end

@testset "other" begin
    @test !Utility.hasduplicates(1:10)
    @test !Utility.hasduplicates(Set(rand(10)))
    @test !Utility.hasduplicates([1, 2, 3, 4])

    @test Utility.hasduplicates([1, 2, 3, 4, 1])
    @test Utility.hasduplicates([1, 2, 1, 4, 3, 2])
    @test Utility.hasduplicates(repeat(rand(5), 2))
end
