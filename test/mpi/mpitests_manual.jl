using ThreadPinning
using MPI
using Test

function check_roundrobin(cpuids_ranks, f_cpuids, nf)
    idomain = 1
    for r in 0:(nranks - 1)
        # @show idomain, cpuids_ranks
        cpuids_domain = f_cpuids(idomain)
        cpuids_rank = cpuids_ranks[r]
        all(c -> c in cpuids_domain, cpuids_rank) || return false
        idomain = mod1(idomain + 1, nf())
    end
    return true
end

MPI.Init()
comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)

for (symb, f, nf) in ((:sockets, socket, nsockets), (:numa, numa, nnuma))
    @test isnothing(mpi_pinthreads(symb, rank, nranks))
    cpuids_ranks = mpi_getcpuids()
    if rank == 0
        @test check_roundrobin(cpuids_ranks, f, nf)
    end
end
