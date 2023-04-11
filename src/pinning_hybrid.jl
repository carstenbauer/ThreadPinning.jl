"""
    pinthreads_hybrid(symbol, proc; kwargs...)

Pin the Julia thread(s) of one of multiple Julia processes to (subsets of) hardware domains
(e.g. sockets or memory domains). Specifically, when calling this function on all
processes, with `proc ∈ 1:nprocs`,
the processes will be distributed in a round-robin fashion among the specified
domains such that their Julia threads are pinned to non-overlapping ranges of CPU-threads
within the domain.

As of now, valid options for `symbol` are `:sockets` and `:numa`.

If `compact=false` (default), physical cores are occupied before hyperthreads. Otherwise,
CPU-cores - with potentially multiple CPU-threads - are filled up one after another
(compact pinning).

The keyword argument `nthreads_per_proc` (default `Threads.nthreads()`) can be used to
pin only a subset of the available Julia threads per process.

*MPI Example:*

```
using ThreadPinning
using MPI
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
pinthreads_hybrid(:sockets, rank+1)
```

*Distributed Example:*
```
using ThreadPinning
using Distributed
addprocs(3) # master (1) + three workers (2,3,4)
@everywhere pinthreads_hybrid(:sockets, myid())
```
"""
function pinthreads_hybrid(symb::Symbol, proc::Integer;
                           nthreads_per_proc = Threads.nthreads(),
                           compact = false, kwargs...)
    cpuids = _cpuids_hybrid(Val(symb), proc; nthreads_per_proc, compact, kwargs...)
    @debug("pinthreads_hybrid", cpuids)
    pinthreads(cpuids; nthreads = nthreads_per_proc, kwargs...)
end

function _cpuids_hybrid(::Val, proc; kwargs...)
    throw(ArgumentError("Unknown domain. Supported domains are `:sockets` and `:numa`."))
end
function _cpuids_hybrid(::Val{:sockets}, proc::Integer; kwargs...)
    return _compute_cpuids_hybrid(proc, socket, nsockets, ncputhreads_per_socket; kwargs...)
end
function _cpuids_hybrid(::Val{:numa}, proc::Integer; kwargs...)
    return _compute_cpuids_hybrid(proc, numa, nnuma, ncputhreads_per_numa; kwargs...)
end

function _compute_cpuids_hybrid(proc::Integer, func_domain, func_ndomain,
                                func_ncputhreads_per_domain;
                                nthreads_per_proc = Threads.nthreads(), compact = false)
    idx_in_domain, domainidx = divrem(proc - 1, func_ndomain()) .+ 1
    idcs = ((idx_in_domain - 1) * nthreads_per_proc + 1):(idx_in_domain * nthreads_per_proc)
    if maximum(idcs) >= func_ncputhreads_per_domain()[domainidx]
        error("Out of bounds: Too many Julia threads (or processes) per domain.")
    end
    cpuids = func_domain(domainidx, idcs; compact)
    return cpuids
end
