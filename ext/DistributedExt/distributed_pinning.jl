function ThreadPinning.distributed_pinthreads(symb::Symbol;
        compact = false,
        include_master = false,
        kwargs...)
    domain_symbol2functions(symb) # to check input arg as early as possible
    dist_topo = ThreadPinning.distributed_topology(; include_master)
    @sync for worker in dist_topo
        Distributed.remotecall(
            () -> ThreadPinning._distributed_pinyourself(
                symb, dist_topo; compact, kwargs...),
            worker.pid)
    end
    return
end

function ThreadPinning._distributed_pinyourself(symb, dist_topo; compact, kwargs...)
    # println("_distributed_pinyourself START")
    idx = findfirst(w -> w.pid == Distributed.myid(), dist_topo)
    if isnothing(idx)
        error("Couldn't find myself (worker pid $(Distributed.myid())) in distributed topology.")
    end
    localid = dist_topo[idx].localid
    domain, ndomain = domain_symbol2functions(symb)
    # compute cpuids
    cpuids = cpuids_of_localid(localid, domain, ndomain; compact)
    # actual pinning
    ThreadPinning.pinthreads(cpuids; kwargs...)
    # println("_distributed_pinyourself STOP")
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

function cpuids_of_localid(localrank, domain, ndomain;
        nthreads_per_proc = Threads.nthreads(),
        compact = false)
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
