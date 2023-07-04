include("common.jl")
using Test
using ThreadPinning

@testset "Set/Get Thread Affinity" begin
    # calling thread
    for cpuids in (node(1:2), node(2:3), socket(1), nsockets() >= 2 ? socket(2, 1:2) : numa(1, 1:2))
        @test isnothing(setaffinity(cpuids))
        @test ThreadPinning.get_cpuids_from_affinity_mask() == cpuids
    end

    # other thread
    for cpuids in (node(1:2), node(2:3), socket(1), nsockets() >= 2 ? socket(2, 1:2) : numa(1, 1:2))
        @test isnothing(setaffinity(1, cpuids))
        @test ThreadPinning.get_cpuids_from_affinity_mask(1) == cpuids
    end
end
