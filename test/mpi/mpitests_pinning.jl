using ThreadPinning
using MPI
using Test

function check_roundrobin(cpuids_ranks, f_cpuids, nf)
    idomain = 1
    for r in 0:(length(cpuids_ranks) - 1)
        @show r, idomain, cpuids_ranks
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
    @test isnothing(mpi_pinthreads(symb))
    cpuids_ranks = mpi_getcpuids()
    hostnames_ranks = mpi_gethostnames()
    if rank == 0
        nodes = unique(values(hostnames_ranks))
        for n in nodes
            # on each node we expect round-robin order
            ranks_onnode = collect(keys(filter(p -> p[2] == n, hostnames_ranks)))
            cpuids_ranks_onnode = filter(p -> p[1] in ranks_onnode, cpuids_ranks)
            @show n, cpuids_ranks_onnode
            @test check_roundrobin(cpuids_ranks_onnode, f, nf)
        end
    end
end
