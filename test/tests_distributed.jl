include("common.jl")
using Test
using ThreadPinning
using Distributed: Distributed

function check_roundrobin(cpuids_dict, f_cpuids, nf)
    idomain = 1
    for pid in sort!(collect(keys(cpuids_dict)))
        # @show pid, idomain, cpuids_dict[pid]
        cpuids_domain = f_cpuids(idomain)
        cpuids_worker = cpuids_dict[pid]
        all(c -> c in cpuids_domain, cpuids_worker) || return false
        idomain = mod1(idomain + 1, nf())
    end
    return true
end

function dist_querying_tests()
    workerpids = Distributed.workers()

    # distributed_getcpuids
    cpuids_dict = distributed_getcpuids()
    @test cpuids_dict isa Dict{Int, Vector{Int}}
    @test length(keys(cpuids_dict)) == nworkers
    for (pid, cpuids_worker) in cpuids_dict
        @test pid in workerpids
        @test length(cpuids_worker) == nthreads_of_workers[pid]
    end
    cpuids_dict = distributed_getcpuids(; include_master = true)
    @test 1 in keys(cpuids_dict)
    @test length(keys(cpuids_dict)) == nworkers + 1

    # distributed_gethostnames
    hostnames_dict = distributed_gethostnames()
    @test hostnames_dict isa Dict{Int, String}
    @test length(keys(hostnames_dict)) == nworkers
    for (pid, hostname_worker) in hostnames_dict
        @test pid in workerpids
        @test hostname_worker == gethostname() # we run this test only on a single node
    end
    hostnames_dict = distributed_gethostnames(; include_master = true)
    @test 1 in keys(hostnames_dict)
    @test length(keys(hostnames_dict)) == nworkers + 1

    # distributed_getispinned
    ispinned_dict = distributed_getispinned()
    @test ispinned_dict isa Dict{Int, Vector{Bool}}
    @test length(keys(ispinned_dict)) == nworkers
    for (pid, ispinned_worker) in ispinned_dict
        @test pid in workerpids
        @test length(ispinned_worker) == nthreads_of_workers[pid]
    end
    ispinned_dict = distributed_getispinned(; include_master = true)
    @test 1 in keys(ispinned_dict)
    @test length(keys(ispinned_dict)) == nworkers + 1
    return
end

function dist_pinning_tests()
    # unpinning
    @test isnothing(distributed_unpinthreads(; include_master = true))
    @test all(
        iszero, Iterators.flatten(values(distributed_getispinned(; include_master = true))))

    # pinning
    @test isnothing(distributed_pinthreads(:sockets))
    @test all(isone, Iterators.flatten(values(distributed_getispinned())))

    # pinning (correct cpuids)
    for (symb, f, nf) in ((:sockets, socket, nsockets), (:numa, numa, nnuma))
        @test isnothing(distributed_pinthreads(symb))
        cpuids_dict = distributed_getcpuids()
        hostnames_dict = distributed_gethostnames()
        nodes = unique(values(hostnames_dict))
        for n in nodes
            # on each node we expect round-robin order
            workers_onnode = collect(keys(filter(p -> p[2] == n, hostnames_dict)))
            cpuids_workers_onnode = filter(p -> p[1] in workers_onnode, cpuids_dict)
            @test check_roundrobin(cpuids_workers_onnode, f, nf)
        end
    end

    # unpinning (after pinning)
    @test isnothing(distributed_unpinthreads())
    @test all(iszero, Iterators.flatten(values(distributed_getispinned())))
    return
end

const nworkers = min(ncputhreads(), 4)
const julia_num_threads_for_workers = 1

# start workers
withenv("JULIA_NUM_THREADS" => julia_num_threads_for_workers) do
    Distributed.addprocs(nworkers)
end
Distributed.@everywhere using ThreadPinning
const nthreads_of_workers = Dict(pid => (i == 1 ? Threads.nthreads() :
                                         julia_num_threads_for_workers)
for (i, pid) in enumerate(vcat([1], Distributed.workers()))
)

# run tests
try
    @testset "HostSystem" begin
        println("")
        @warn("\nHostSystem\n")
        dist_querying_tests()
        dist_pinning_tests()
    end

    @testset "TestSystems" begin
        # for name in ("PerlmutterComputeNode",)
        for name in ThreadPinning.Faking.systems()
            println("")
            @warn("\nTestSystem: $name\n")
            Distributed.@everywhere ThreadPinning.Faking.start($name)
            @testset "$name" begin
                dist_querying_tests()
                dist_pinning_tests()
            end
            Distributed.@everywhere ThreadPinning.Faking.stop()
        end
        println()
    end
finally
    # cleanup
    Distributed.rmprocs(Distributed.workers())
    ThreadPinning.Faking.stop()
end
