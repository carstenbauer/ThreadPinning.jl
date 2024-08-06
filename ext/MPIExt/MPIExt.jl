module MPIExt

import ThreadPinning: ThreadPinning
using MPI: MPI

# querying
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
    # three columns: rankid, nodeid, localid
    # mpi_topo = Matrix{Int}(undef, length(hostnames_ranks), 3)
    mpi_topo = Vector{@NamedTuple{
        rank::Int64, localrank::Int64, node::Int64, nodename::String}}(
        undef, length(hostnames_ranks))
    nodes = unique(values(hostnames_ranks))
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

# pinning
function ThreadPinning.mpi_pinthreads(symb::Symbol;
        comm = MPI.COMM_WORLD,
        compact = false,
        nthreads_per_rank = Threads.nthreads(),
        kwargs...)
    if symb == :sockets
        domain = ThreadPinning.socket
        ndomain = ThreadPinning.nsockets
    elseif symb == :numa
        domain = ThreadPinning.numa
        ndomain = ThreadPinning.nnuma
    elseif symb == :cores
        domain = ThreadPinning.core
        ndomain = ThreadPinning.ncores
    else
        throw(ArgumentError("Invalid symbol. Supported symbols are :sockets, :numa, and :cores."))
    end
    localrank = ThreadPinning.mpi_getlocalrank(; comm)
    cpuids = cpuids_of_localrank(localrank, domain, ndomain; nthreads_per_rank, compact)
    ThreadPinning.pinthreads(cpuids; nthreads = nthreads_per_rank, kwargs...)
    return
end

function cpuids_of_localrank(
        localrank, domain, ndomain; nthreads_per_rank = Threads.nthreads(), compact = false)
    i_in_domain, idomain = divrem(localrank, ndomain()) .+ 1
    idcs = ((i_in_domain - 1) * nthreads_per_rank + 1):(i_in_domain * nthreads_per_rank)
    if maximum(idcs) > length(domain(idomain))
        @show maximum(idcs), length(domain(idomain))
        error("Too many Julia threads / MPI ranks for the selected domain.")
    end
    if domain == ThreadPinning.core
        cpuids = domain(idomain, idcs)
    else
        cpuids = domain(idomain, idcs; compact)
    end
    return cpuids
end

end # module
