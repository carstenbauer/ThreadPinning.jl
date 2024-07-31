include("common.jl")
using Test
using ThreadPinning
using Base.Threads: nthreads
using Random: shuffle, shuffle!

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

const firsttid = first(ThreadPinning.threadids(; threadpool = :default))
const randtid = rand(ThreadPinning.threadids(; threadpool = :default))

# get two valid cpu ids on the current system
function get_two_cpuids()
    all_cpuids = ThreadPinning.cpuids()
    cpuid1 = getcpuid()
    cpuid1_idx = findfirst(==(cpuid1), all_cpuids)
    deleteat!(all_cpuids, cpuid1_idx)
    # find another cpuid that is close to the one before
    _, idx = findmin(x -> abs(x - cpuid1), all_cpuids)
    cpuid2 = all_cpuids[idx]
    return cpuid1, cpuid2
end

function pinning_tests()
    @testset "pinning: explicit" begin
        cpuid1, cpuid2 = get_two_cpuids()
        @test isnothing(pinthread(cpuid1))
        @test getcpuid() == cpuid1
        @test isnothing(pinthreads([cpuid1, cpuid2]; nthreads = 2, threadpool = :default))
        @test getcpuids()[1:2] == [cpuid1, cpuid2]
        @test isnothing(pinthreads([cpuid2, cpuid1]; nthreads = 2, threadpool = :default))
        @test getcpuids()[1:2] == [cpuid2, cpuid1]

        for cpuid in (cpuid1, cpuid2)
            @test isnothing(pinthread(cpuid; threadid = randtid))
            @test getcpuid(; threadid = randtid) == cpuid
        end
    end

    @testset "pinning: symbols" begin
        @testset ":random" begin
            @test isnothing(pinthreads(:random))
            # can we test more here?
        end
        @testset ":current" begin
            pinthreads(:random)
            cpuids_before = getcpuids()
            @test isnothing(pinthreads(:current))
            cpuids_after = getcpuids()
            @test cpuids_before == cpuids_after
        end
        @testset ":firstn" begin
            pinthreads(:random)
            @test isnothing(pinthreads(:firstn))
            @test getcpuids() == sort!(ThreadPinning.cpuids())[1:nthreads()]
        end
        @testset ":cputhreads" begin
            pinthreads(:random)
            @test isnothing(pinthreads(:cputhreads; nthreads = 2))
            @test getcpuids()[1:2] == node(1:2; compact = true)
        end
        @testset ":cores" begin
            pinthreads(:random)
            @test isnothing(pinthreads(:cores; nthreads = 2))
            @test getcpuids()[1:2] == node(1:2; compact = false)
        end
        @testset ":numa" begin
            pinthreads(:random)
            @test isnothing(pinthreads(:numa; nthreads = 2))
            if nnuma() > 1
                @test getcpuids()[1:2] == vcat(numa(1, 1), numa(2, 1))
            else
                @test getcpuids()[1:2] == numa(1, 1:2)
            end
        end
        @testset ":sockets" begin
            pinthreads(:random)
            @test isnothing(pinthreads(:sockets; nthreads = 2))
            if nsockets() > 1
                @test getcpuids()[1:2] == vcat(socket(1, 1), socket(2, 1))
            else
                @test getcpuids()[1:2] == socket(1, 1:2)
            end
        end
        if !ThreadPinning.Faking.isfaking()
            @testset ":affinitymask" begin
                test_external_affinity = (cmd, numthreads, code) -> begin
                    julia = Base.julia_cmd()
                    pkgdir = joinpath(@__DIR__, "..")
                    juliacmd = `$julia --project=$(pkgdir) -t $numthreads -e $code`
                    fullcmd = `$cmd $juliacmd`
                    # @show fullcmd
                    run(fullcmd).exitcode == 0
                end

                numthreads = min(Threads.nthreads(), ncputhreads())
                cpuids = sort!(shuffle!(ThreadPinning.cpuids())[1:numthreads])
                cpulist = join(cpuids, ",")
                # Check
                # 1) all in mask
                # 2) unique / no overlap
                # 3) hyperthreads last
                code = `"using ThreadPinning, Test;
                        pinthreads(:affinitymask)
                        mask_cpuids = [$cpulist]
                        @test all(c->c in mask_cpuids, getcpuids())
                        @test length(getcpuids()) == length(Set(getcpuids()))
                        @test issorted(ishyperthread.(getcpuids()))"`
                unpinthreads()
                @testset "taskset" begin
                    @test test_external_affinity(`taskset --cpu-list $cpulist`,
                        numthreads, code)
                end
                # unpinthreads()
                # @testset "numactl" begin @test test_external_affinity(`numactl -C $cpulist`,
                #                                                       numthreads, code) end
            end
        end
    end

    @testset "pinning: logical" begin
        @testset "domains" begin
            pinthreads(:random)
            @test isnothing(pinthreads(core(1, 1:1)))
            @test getcpuids()[1:1] == core(1, 1:1)
            for f in (socket,)
                for compact in (false, true)
                    pinthreads(:random)
                    @test isnothing(pinthreads(f(1, 1:2; compact)))
                    @test getcpuids()[1:2] == f(1, 1:2; compact)
                end
            end
            pinthreads(:random)
            @test isnothing(pinthreads(node(1:2)))
            @test getcpuids()[1:2] == node(1:2)
        end

        @testset "concatenation" begin
            pinthreads(:random)
            @test isnothing(pinthreads(core(1, 1:1), core(2, 1:1)))
            @test getcpuids()[1:2] == vcat(core(1, 1:1), core(2, 1:1))
            pinthreads(:random)
            @test isnothing(pinthreads([core(1, 1:1), core(2, 1:1)]))
            @test getcpuids()[1:2] == vcat(core(1, 1:1), core(2, 1:1))
        end
    end

    @testset "with_pinthreads" begin
        c_prior = getcpuids()
        c_masks_prior = Vector{Cchar}[]
        tids = ThreadPinning.threadids(; threadpool = :default)
        nt = length(tids)
        for i in tids
            push!(c_masks_prior, ThreadPinning.getaffinity(; threadid = i))
        end
        @test with_pinthreads(:cores) do
            getcpuids()
        end == node(1:nt; compact = false)
        @test getcpuids() == c_prior
        c_masks = Vector{Cchar}[]
        for i in tids
            push!(c_masks, ThreadPinning.getaffinity(; threadid = i))
        end
        @test c_masks == c_masks_prior
    end

    @testset "unpinning" begin
        pinthreads(:random)
        tids = ThreadPinning.threadids(; threadpool = :default)
        for threadid in tids
            @test ispinned(; threadid)
        end

        tid1 = first(tids)
        @test isnothing(unpinthread(; threadid = tid1))
        @test !ispinned(; threadid = tid1)

        unpinthreads()
        for threadid in tids
            @test !ispinned(; threadid)
        end
    end

    @testset "setaffinity" begin
        mask = getaffinity()
        @test isnothing(setaffinity(mask))
        @test isnothing(setaffinity(mask; threadid = randtid))

        cpuid1, cpuid2 = get_two_cpuids()
        @test isnothing(setaffinity_cpuids([cpuid2, cpuid1]))
        @test ThreadPinning.Utility.affinitymask2cpuids(getaffinity())[1:2] ==
              [cpuid2, cpuid1]
        @test isnothing(setaffinity_cpuids([cpuid2, cpuid1]; threadid = randtid))
    end
end

@testset "TestSystems" begin
    for name in ThreadPinning.Faking.systems()
        println("")
        @warn("\nTestSystem: $name\n")
        ThreadPinning.Faking.with(name) do
            @testset "$name" begin
                pinning_tests()
            end
        end
    end
    println()
end

# @testset "Environment variables" begin
#     julia = Base.julia_cmd()
#     pkgdir = joinpath(@__DIR__, "..")

#     function exec(s; nthreads = ncores())
#         run(`$julia --project=$(pkgdir) -t $nthreads -e $s`).exitcode == 0
#     end
#     @testset "JULIA_PIN" begin
#         withenv("JULIA_PIN" => "cputhreads") do
#             @test exec(`'using ThreadPinning, Test;
#                 @test getcpuids() == node(1:Threads.nthreads(); compact=true)'`)
#         end
#         withenv("JULIA_PIN" => "cores") do
#             @test exec(`'using ThreadPinning, Test;
#                 @test getcpuids() == node(1:Threads.nthreads(); compact=false)'`)
#         end
#     end
#     @testset "JULIA_LIKWID_PIN" begin
#         withenv("JULIA_LIKWID_PIN" => "N:0-$(ncores()-1)") do
#             @test exec(`'using ThreadPinning, Test;
#                 @test getcpuids() == node(1:Threads.nthreads(); compact=false)'`)
#         end
#         withenv("JULIA_LIKWID_PIN" => "E:N:$(ncores())") do
#             @test exec(`'using ThreadPinning, Test;
#                 @test getcpuids() == node(1:Threads.nthreads(); compact=true)'`)
#         end
#     end
# end
