module MPIExt

import ThreadPinning: ThreadPinning
using MPI: MPI

function ThreadPinning.mpi_pinthreads(symb::Symbol, args...; comm = MPI.COMM_WORLD,
        kwargs...)
    rank = MPI.Comm_rank(comm)
    ThreadPinning.pinthreads_hybrid(symb, rank + 1)
end

function ThreadPinning.mpi_getcpuids(; comm = MPI.COMM_WORLD, dest = 0)
    rank = MPI.Comm_rank(comm)
    cpuids_ranks = MPI.Gather(ThreadPinning.getcpuids(), comm; root = dest)
    rank != 0 && return
    n_per_rank = Threads.nthreads()
    return Dict((k - 1) => collect(v)
    for (k, v) in enumerate(Iterators.partition(cpuids_ranks, n_per_rank)))
end

function ThreadPinning.mpi_gethostnames(; comm = MPI.COMM_WORLD, dest = 0)
    rank = MPI.Comm_rank(comm)
    hostnames_ranks = MPI.gather(gethostname(), comm; root = dest)
    rank != 0 && return
    return Dict((k - 1) => only(v)
    for (k, v) in enumerate(Iterators.partition(hostnames_ranks, 1)))
end

function compute_localranks(hostnames_ranks)
    localranks = fill(-1, length(hostnames_ranks))
    nodes = unique(values(hostnames_ranks))
    for n in nodes
        ranks_onnode = collect(keys(filter(p -> p[2] == n, hostnames_ranks)))
        sort!(ranks_onnode) # on each node we sort by rank id
        for (i, r) in enumerate(ranks_onnode)
            localranks[r + 1] = i - 1 # -1 because local ranks should start at 0
        end
    end
    return localranks
end

function ThreadPinning.mpi_getlocalrank(; comm = MPI.COMM_WORLD)
    hostnames_ranks = ThreadPinning.mpi_gethostnames()
    rank = MPI.Comm_rank(comm)
    localranks = nothing
    if rank == 0
        localranks = compute_localranks(hostnames_ranks)
    end
    localrank = MPI.scatter(localranks, comm; root = 0)
    return localrank
end

end # module
