include("common.jl")
using Test
using ThreadPinning

function threadinfo_tests()
    @test isnothing(threadinfo())
    redirect_stdout(Base.DevNull()) do # avoid too much output
        @test isnothing(threadinfo(; groupby = :numa))
        @test isnothing(threadinfo(; groupby = :sockets))
        @test isnothing(threadinfo(; groupby = :cores))
        @test isnothing(threadinfo(; threadpool = :default))
        @test isnothing(threadinfo(; threadpool = :interactive))
        @test isnothing(threadinfo(; blas = true))
        @test isnothing(threadinfo(; blas = false))
        @test isnothing(threadinfo(; slurm = true))
        @test isnothing(threadinfo(; slurm = false))
        @test isnothing(threadinfo(; hints = true))
        @test isnothing(threadinfo(; hints = false))
        @test isnothing(threadinfo(; compact = true))
        @test isnothing(threadinfo(; compact = false))
        @test isnothing(threadinfo(; hyperthreads = true))
        @test isnothing(threadinfo(; hyperthreads = false))
        @test isnothing(threadinfo(; efficiency = true))
        @test isnothing(threadinfo(; efficiency = false))
        @test isnothing(threadinfo(; masks = true))
        @test isnothing(threadinfo(; masks = false))
        @test isnothing(threadinfo(; coregaps = true))
        @test isnothing(threadinfo(; coregaps = false))
        @test isnothing(threadinfo(; logical = true))
        @test isnothing(threadinfo(; logical = false))
        @test isnothing(threadinfo(; color = true))
        @test isnothing(threadinfo(; color = false))
        @test isnothing(threadinfo(; blocksize = 5))
    end
end

@testset "TestSystems" begin
    for name in ThreadPinning.Faking.systems()
        println("")
        @warn("\nTestSystem: $name\n")
        ThreadPinning.Faking.with(name) do
            @testset "$name" begin
                threadinfo_tests()
            end
        end
    end
    println()
end
