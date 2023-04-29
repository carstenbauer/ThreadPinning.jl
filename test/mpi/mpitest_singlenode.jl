using MPI
using ThreadPinning
using Test

@test Threads.nthreads() == 2

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
nranks = MPI.Comm_size(comm)

for t in [
    (symb = :sockets, cpuids_per_domain = cpuids_per_socket, ndomain = nsockets),
    (symb = :numa, cpuids_per_domain = cpuids_per_numa, ndomain = nnuma),
]
    @test isnothing(pinthreads_mpi(t.symb))

    cpuids_dict = getcpuids_mpi()
    # if rank == 0
    #     @show cpuids
    # end
    if rank == 0
        @test typeof(cpuids_dict) == ThreadPinning.OrderedDict{Int64, Vector{Int64}}
        @test length(cpuids_dict) == nranks
        @test all(x -> length(x) == Threads.nthreads(), values(cpuids_dict))

        # test that the cpuids for each rank are within the correct domain (i.e. round-robin)
        for (k, v) in cpuids_dict
            @test all(c -> c in t.cpuids_per_domain()[mod(k, t.ndomain()) + 1], v)
        end
    else
        @test isnothing(cpuids_dict)
    end
end
