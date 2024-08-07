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
    res = Dict{Int, Vector{Bool}}()
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
