using Test
using ThreadPinning

@testset "OMP_PLACES" begin
    @testset "_omp_list_to_jl_array" begin
        @test ThreadPinning._omp_list_to_jl_array("0,1,2,3") == [0,1,2,3]
        @test ThreadPinning._omp_list_to_jl_array("0,4,2,10") == [0,4,2,10]
    end

    @testset "_omp_range_to_jl_array" begin
        @test_throws ArgumentError ThreadPinning._omp_range_to_jl_array("0,1,2,3")
        # NUM:NUM
        @test ThreadPinning._omp_range_to_jl_array("0:4") == [0,1,2,3]
        @test ThreadPinning._omp_range_to_jl_array("4:4") == [4,5,6,7]
        @test ThreadPinning._omp_range_to_jl_array("12:4") == [12,13,14,15]
        # NUM:NUM:NUM (not supported yet)
        @test_broken ThreadPinning._omp_range_to_jl_array("12:4:2")
        # {NUMS...}:NUM:NUM (not supported yet)
        @test_broken ThreadPinning._omp_range_to_jl_array("{0:1}:8:32")
    end

    @testset "Testcases (high-level)" begin
        @test ThreadPinning._omp_places_env_parse("threads") isa Vector{Vector{Int}}
        @test ThreadPinning._omp_places_env_parse("threads") == [cpuids_all()]
        @test ThreadPinning._omp_places_env_parse("sockets") isa Vector{Vector{Int}}
        @test ThreadPinning._omp_places_env_parse("sockets") == cpuids_per_socket()
        @test ThreadPinning._omp_places_env_parse("cores") isa Vector{Vector{Int}}
        @test ThreadPinning._omp_places_env_parse("cores") == [filter(!ishyperthread, cpuids_all())]

        # not implemented yet
        @test_broken ThreadPinning._omp_places_env_parse("threads(10)") isa Vector{Vector{Int}}
        @test_broken ThreadPinning._omp_places_env_parse("threads(10)") == [cpuids_all()[1:10]]
        @test_broken ThreadPinning._omp_places_env_parse("sockets(1)") isa Vector{Vector{Int}}
        @test_broken ThreadPinning._omp_places_env_parse("sockets(1)") == cpuids_per_socket()[1:1]
        @test_broken ThreadPinning._omp_places_env_parse("cores(10)") isa Vector{Vector{Int}}
        @test_broken ThreadPinning._omp_places_env_parse("cores(10)") == [filter(!ishyperthread, cpuids_all())[1:10]]
    end

    @testset "Testcases (specific lists)" begin
        desired_result = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
        OMP_PLACES_strs = [
            "{0,1,2,3},{4,5,6,7},{8,9,10,11},{12,13,14,15}",
            "{0:4},{4:4},{8:4},{12:4}",
            "{0,1,2,3},{4:4},{8,9,10,11},{12:4}",
        ]
        for places in OMP_PLACES_strs
            @test ThreadPinning._omp_places_env_parse(places) == desired_result
        end
    end
end
