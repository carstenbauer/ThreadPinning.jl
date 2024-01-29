include("common.jl")
using ThreadPinning
using ThreadPinning: @spawnat
using LinearAlgebra
using Test

@testset "interweave" begin
    @test ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8]) ==
          [1, 5, 2, 6, 3, 7, 4, 8]
    @test ThreadPinning.interweave(1:4, 5:8) == [1, 5, 2, 6, 3, 7, 4, 8]
    @test ThreadPinning.interweave(1:4, 5:8, 9:12) ==
          [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
    # different size inputs
    @test_throws ArgumentError ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8, 9])

    @test ThreadPinning.interweave_binary([1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12]) ==
          [1, 9, 2, 10, 3, 11, 4, 12, 5, 6, 7, 8]
    @test ThreadPinning.interweave_binary([1, 2, 3, 4], [5, 6, 7, 8, 9, 10, 11, 12]) ==
          [1, 5, 2, 6, 3, 7, 4, 8, 9, 10, 11, 12]
end

# @testset "threadids" begin
#     @static if VERSION < v"1.9-"
#         @test ThreadPinning.threadids() == 1:Threads.nthreads()
#     else
#         @test ThreadPinning.threadids(:all) == 1:(Threads.nthreads(:default) + Threads.nthreads(:interactive)) # no IJulia here :)
#         # :interactive threads first, then :default threads
#         @test ThreadPinning.threadids(:interactive) == 1:Threads.nthreads(:interactive)
#         @test ThreadPinning.threadids(:default) == (1:Threads.nthreads(:default)) .+ Threads.nthreads(:interactive)
#     end
# end

@testset "spawnat" begin
    @static if VERSION < v"1.9-"
        for tid in 1:Threads.nthreads()
            @test fetch(@spawnat tid Threads.threadid()) == tid
        end
    else
        ntdefault = Threads.nthreads(:default)
        ntinteractive = Threads.nthreads(:interactive)
        for tid in ThreadPinning.threadids(:all)
            @test fetch(@spawnat tid Threads.threadid()) == tid
        end
        for tid in ThreadPinning.threadids(:default)
            @test fetch(@spawnat tid Threads.threadpool()) == :default
        end
        for tid in ThreadPinning.threadids(:interactive)
            @test fetch(@spawnat tid Threads.threadpool()) == :interactive
        end
    end
end

@testset "BLAS utility" begin
    @test contains(ThreadPinning.BLAS_lib(), "openblas")
    @test ThreadPinning.nblasthreads() == BLAS.get_num_threads()
end

@testset "other" begin
    @test !ThreadPinning.hasduplicates(1:10)
    @test !ThreadPinning.hasduplicates(Set(rand(10)))
    @test !ThreadPinning.hasduplicates([1,2,3,4])

    @test ThreadPinning.hasduplicates([1,2,3,4,1])
    @test ThreadPinning.hasduplicates([1,2,1,4,3,2])
    @test ThreadPinning.hasduplicates(repeat(rand(5), 2))
end
