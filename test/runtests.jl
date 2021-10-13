using ThreadPinning
using Test

@testset "ThreadPinning.jl" begin
    @testset "Helper" begin
        @test ThreadPinning.interweave([1,2,3,4], [5,6,7,8]) == [1,5,2,6,3,7,4,8]
        # different size inputs
        @test_throws ArgumentError ThreadPinning.interweave([1,2,3,4], [5,6,7,8,9])
    end

    @testset "Hwloc loaded" begin
        include("test_hwloc.jl")
    end
end
