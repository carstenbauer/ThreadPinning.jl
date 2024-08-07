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
