using ThreadPinning
using MPI
using Test

const MPIExt = Base.get_extension(ThreadPinning, :MPIExt)

MPI.Init()
comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

# mpi_getcpuids
cpuids_ranks = mpi_getcpuids()
if rank == 0
    @test cpuids_ranks isa Dict{Int, Vector{Int}}
    @test length(keys(cpuids_ranks)) == nranks
    for (rnk, cpuids_rnk) in cpuids_ranks
        @test 0 <= rnk < nranks
        @test length(cpuids_rnk) == Threads.nthreads()
    end
else
    @test isnothing(cpuids_ranks)
end

# mpi_gethostnames
hostnames_ranks = mpi_gethostnames()
if rank == 0
    @test hostnames_ranks isa Dict{Int, String}
    @test length(keys(hostnames_ranks)) == nranks
    for (rnk, hostname_rnk) in hostnames_ranks
        @test 0 <= rnk < nranks
        @test hostname_rnk == gethostname() # we only run this test on a single node
    end
else
    @test isnothing(hostnames_ranks)
end

# mpi_getlocalrank
if rank == 0
    hostnames_ranks = Dict(
        0 => "node3", 5 => "node3", 6 => "node2", 3 => "node1",
        4 => "node2", 2 => "node1", 1 => "node3")
    mpi_topo = MPIExt.compute_mpi_topology(hostnames_ranks)
    @test [r.rank for r in mpi_topo] == 0:6
    @test [r.localrank for r in mpi_topo] == [0, 1, 0, 1, 0, 2, 1]
    @test [r.node for r in mpi_topo] == [1, 1, 3, 3, 2, 1, 2]
    @test [r.nodename for r in mpi_topo] ==
          ["node3", "node3", "node1", "node1", "node2", "node3", "node2"]
end
localrank = mpi_getlocalrank()
@test localrank isa Integer
@test 0 <= localrank < nranks
