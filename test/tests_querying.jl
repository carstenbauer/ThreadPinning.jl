include("common.jl")
using Test
using ThreadPinning

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

const firsttid = first(ThreadPinning.threadids(; threadpool = :default))

# Basic tests
@testset "Basics (host system)" begin
    tids = ThreadPinning.threadids(; threadpool = :default)

    @test getcpuid() isa Integer
    @test getcpuid() >= 0
    @test getcpuids() isa Vector{<:Integer}
    @test all(>=(0), getcpuids())
    @test getcpuids() == [getcpuid(; threadid = i) for i in tids]

    @test getaffinity() isa Vector{<:Integer}
    @test getaffinity(; threadid = firsttid) isa Vector{<:Integer}

    @test getnumanode() isa Integer
    @test getnumanodes() isa Vector{<:Integer}
    @test getnumanodes(; threadpool = :default) ==
          [getnumanode(; threadid = i) for i in tids]

    @test core(1) isa Vector{<:Integer}
    @test core(1, 1:1) isa Vector{<:Integer}
    @test socket(1) isa Vector{<:Integer}
    @test socket(1, 1:1) isa Vector{<:Integer}
    @test socket(1; compact = true) isa Vector{<:Integer}
    @test numa(1) isa Vector{<:Integer}
    @test numa(1, 1:1) isa Vector{<:Integer}
    @test numa(1; compact = true) isa Vector{<:Integer}
    @test node(1) isa Vector{<:Integer}
    @test node(1:1) isa Vector{<:Integer}
    @test node(; compact = true) isa Vector{<:Integer}
    @test cores() isa Vector{<:Integer}
    @test sockets() isa Vector{<:Integer}
    @test numas() isa Vector{<:Integer}

    @test isnothing(printaffinities())
    @test isnothing(printaffinities(; threadpool = :default))
    @test isnothing(printaffinity())
    @test isnothing(printaffinity(; threadid = firsttid))
    # @test isnothing(visualize_affinity())
    # TODO kwargs for visualize affinity

    @test ispinned() isa Bool
    @test ispinned(; threadid = firsttid) isa Bool
    @test hyperthreading_is_enabled() isa Bool
    @test ishyperthread(0) == false
    @test isefficiencycore(0) isa Bool

    @test ncputhreads() isa Integer
    @test ncputhreads() >= 1
    @test ncores() isa Integer
    @test ncores() >= 1
    @test nnuma() isa Integer
    @test nnuma() >= 1
    @test nsockets() isa Integer
    @test nsockets() >= 1
    @test ncorekinds() isa Integer
    @test ncorekinds() >= 1
    @test nsmt() isa Integer
    @test nsmt() >= 1

    @test ThreadPinning.cpuids() isa Vector{<:Integer}
    @test ThreadPinning.id(0) isa Integer
    @test ThreadPinning.cpuid(1) isa Integer
end
