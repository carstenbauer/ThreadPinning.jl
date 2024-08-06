include("common.jl")
using Test
using ThreadPinning

@testset "tests no-ops" begin
    for args in (:cores, :sockets, :affinitymask, :cputhreads, :numa, 1:3, [1, 2, 3])
        for kwargs in ((;), (; nthreads = 2), (; threadpool = :interactive))
            @test isnothing(pinthreads(args; kwargs...))
        end
    end
    @test isnothing(pinthread(3))
    @test isnothing(pinthread(3; threadid = 10))
    @test isnothing(unpinthreads())
    @test isnothing(unpinthreads(; threadpool = :default))
    @test isnothing(unpinthread())
    @test isnothing(unpinthread(; threadid = 10))
    @test isnothing(setaffinity([1, 0, 0, 1]))
    @test isnothing(setaffinity_cpuids([0, 1, 2, 3]))
    @test with_pinthreads(:cores) do
        3 + 3
    end == 6
    @test isnothing(pinthreads_likwidpin("M1:0,2,4"))
    @test isnothing(mpi_pinthreads(:sockets, 0, 3))
end
