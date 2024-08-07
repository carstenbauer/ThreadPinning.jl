module DistributedExt

import ThreadPinning: ThreadPinning
using Distributed: Distributed

function getworkerpids(; include_master = false)
    workers = Distributed.workers()
    if include_master && !in(1, workers)
        pushfirst!(workers, 1)
    end
    return workers
end

# querying
function ThreadPinning.distributed_getcpuids(; include_master = false)
    res = Dict{Int, Vector{Int}}()
    for w in getworkerpids(; include_master)
        res[w] = Distributed.@fetchfrom w ThreadPinning.getcpuids()
    end
    return res
end

function ThreadPinning.distributed_gethostnames(; include_master = false)
    res = Dict{Int, String}()
    for w in getworkerpids(; include_master)
        res[w] = Distributed.@fetchfrom w gethostname()
    end
    return res
end

function ThreadPinning.distributed_getispinned(; include_master = false)
    res = Dict{Int, Any}()
    for w in getworkerpids(; include_master)
        res[w] = Distributed.@fetchfrom w ThreadPinning.getispinned()
    end
    return res
end

function compute_distributed_topology(hostnames_dict)
    dist_topo = Vector{@NamedTuple{
        pid::Int64, localid::Int64, node::Int64, nodename::String}}(
        undef, length(hostnames_dict))
    sorted_by_pid = sortperm(collect(keys(hostnames_dict)))
    nodes = unique(collect(values(hostnames_dict))[sorted_by_pid])
    idx = 1
    for (inode, node) in enumerate(nodes)
        workers_onnode = collect(keys(filter(p -> p[2] == node, hostnames_dict)))
        sort!(workers_onnode) # on each node we sort by worker pid
        for (i, r) in enumerate(workers_onnode)
            dist_topo[idx] = (; pid = r, localid = i - 1, node = inode, nodename = node)
            idx += 1
        end
    end
    return dist_topo
end

function ThreadPinning.distributed_topology(; include_master = false)
    hostnames_dict = ThreadPinning.distributed_gethostnames(; include_master)
    dist_topo = compute_distributed_topology(hostnames_dict)
    return dist_topo
end

# pinning
function ThreadPinning.distributed_pinthreads(symb::Symbol;
        compact = false,
        nthreads_per_proc = Threads.nthreads(),
        include_master = false,
        kwargs...)
    domain_symbol2functions(symb) # to check input arg as early as possible
    dist_topo = ThreadPinning.distributed_topology(; include_master)
    @sync for worker in dist_topo
        Distributed.remotecall(
            () -> ThreadPinning._distributed_pinyourself(
                symb, dist_topo; nthreads_per_proc, compact, kwargs...),
            worker.pid)
    end
    return
end

function ThreadPinning._distributed_pinyourself(
        symb, dist_topo; nthreads_per_proc, compact, kwargs...)
    idx = findfirst(w -> w.pid == Distributed.myid(), dist_topo)
    if isnothing(idx)
        error("Couldn't find myself (worker pid $(Distributed.myid())) in distributed topology.")
    end
    localid = dist_topo[idx].localid
    domain, ndomain = domain_symbol2functions(symb)
    # compute cpuids
    cpuids = cpuids_of_localid(localid, domain, ndomain; nthreads_per_proc, compact)
    # actual pinning
    ThreadPinning.pinthreads(cpuids; nthreads = nthreads_per_proc, kwargs...)
    return
end

function domain_symbol2functions(symb)
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
    return domain, ndomain
end

function cpuids_of_localid(
        localrank, domain, ndomain; nthreads_per_proc = Threads.nthreads(), compact = false)
    i_in_domain, idomain = divrem(localrank, ndomain()) .+ 1
    idcs = ((i_in_domain - 1) * nthreads_per_proc + 1):(i_in_domain * nthreads_per_proc)
    if maximum(idcs) > length(domain(idomain))
        @show maximum(idcs), length(domain(idomain))
        error("Too many Julia threads / Julia workers for the selected domain.")
    end
    if domain == ThreadPinning.core
        cpuids = domain(idomain, idcs)
    else
        cpuids = domain(idomain, idcs; compact)
    end
    return cpuids
end

function ThreadPinning.distributed_unpinthreads(; include_master = false, kwargs...)
    @sync for w in getworkerpids(; include_master)
        Distributed.@spawnat w ThreadPinning.unpinthreads(; kwargs...)
    end
    return
end

end # module
