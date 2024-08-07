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

# function compute_localranks(hostnames_ranks)
#     localranks = fill(-1, length(hostnames_ranks))
#     nodes = unique(values(hostnames_ranks))
#     for n in nodes
#         ranks_onnode = collect(keys(filter(p -> p[2] == n, hostnames_ranks)))
#         sort!(ranks_onnode) # on each node we sort by rank id
#         for (i, r) in enumerate(ranks_onnode)
#             localranks[r + 1] = i - 1 # -1 because local ranks should start at 0
#         end
#     end
#     return localranks
# end

function compute_mpi_topology(hostnames_ranks)
    mpi_topo = Vector{@NamedTuple{
        rank::Int64, localrank::Int64, node::Int64, nodename::String}}(
        undef, length(hostnames_ranks))
    sorted_by_rank = sortperm(collect(keys(hostnames_ranks)))
    nodes = unique(collect(values(hostnames_ranks))[sorted_by_rank])
    for (inode, node) in enumerate(nodes)
        ranks_onnode = collect(keys(filter(p -> p[2] == node, hostnames_ranks)))
        sort!(ranks_onnode) # on each node we sort by rank id
        for (i, r) in enumerate(ranks_onnode)
            mpi_topo[r + 1] = (; rank = r, localrank = i - 1, node = inode, nodename = node)
        end
    end
    return mpi_topo
end

function ThreadPinning.mpi_topology(; comm = MPI.COMM_WORLD)
    hostnames_ranks = ThreadPinning.mpi_gethostnames(; comm)
    rank = MPI.Comm_rank(comm)
    mpi_topo = rank == 0 ? compute_mpi_topology(hostnames_ranks) : nothing
    # mpi_topo = MPI.bcast(mpi_topo, comm)
    return mpi_topo
end

function ThreadPinning.mpi_getlocalrank(; comm = MPI.COMM_WORLD)
    hostnames_ranks = ThreadPinning.mpi_gethostnames(; comm)
    rank = MPI.Comm_rank(comm)
    localranks = nothing
    if rank == 0
        mpi_topo = compute_mpi_topology(hostnames_ranks)
        localranks = [r.localrank for r in mpi_topo]
    end
    localrank = MPI.scatter(localranks, comm; root = 0)
    return localrank
end
