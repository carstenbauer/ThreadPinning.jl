# Distributed (stdlib)

"""
Pin Julia thread(s) of workers (Distributed stdlib), to (subsets of) hardware domains
(e.g. sockets or memory domains). This function is idential to [`pinthreads_hybrid`](@ref)
but automatically queries worker id of the calling worker and sets `proc` accordingly.

The keyword argument `master` (default `false`) can be used to toggle whether the master
should be considered as a worker and be pinned as well.
"""
function pinthreads_distributed(symb::Symbol, args...; master = false,
                                kwargs...)
    proc = _worker2proc(; master)
    @debug("pinthreads_distributed", proc)
    if master || myid() != 1
        pinthreads_hybrid(symb, proc; kwargs...)
    end
end

function _worker2proc(; master = false)
    num = findfirst(isequal(myid()), sort(workers()))
    if !master
        return num
    else
        return myid() == 1 ? 1 : num + 1
    end
end

"""
TODO
"""
function getcpuids_distributed()
    if myid() != 1
        error("getcpuids_distributed may only be called on the Julia master process.")
    end
    worker_cpuids = OrderedDict{Int, Vector{Int}}()
    worker_cpuids[myid()] = getcpuids()
    for worker in sort(workers())
        worker_cpuids[worker] = @fetchfrom worker ThreadPinning.getcpuids()
    end
    return worker_cpuids
end
