"""
    pinthreads_mpi(symbol, rank, nranks; nthreads_per_rank, compact, kwargs...)

Pin MPI ranks, that is, their respective Julia thread(s), to (subsets of) domains
(e.g. sockets or memory domains). Specifically, when calling this function on all
MPI ranks, the latter will be distributed in a round-robin fashion among the specified
domains such that their Julia threads are pinned to non-overlapping ranges of CPU-threads
within the domain.

Valid options for `symbol` are `:sockets` and `:numa`.

If `compact=false` (default), physical cores are occupied before hyperthreads. Otherwise,
CPU-cores - with potentially multiple CPU-threads - are filled up one after another
(compact pinning).

The keyword argument `nthreads_per_rank` (default `Threads.nthreads()`) can be used to
pin only a subset of the available Julia threads per MPI rank.

**Note:**
As per usual for MPI, `rank` starts at zero.

*Example:*

```
using ThreadPinning
using MPI
comm = MPI.COMM_WORLD
nranks = MPI.Comm_size(comm)
rank = MPI.Comm_rank(comm)
pinthreads_mpi(:sockets, rank, nranks)
```
"""
function pinthreads_mpi(symb::Symbol, args...; kwargs...)
    pinthreads_mpi(Val(symb), args...; kwargs...)
end

function pinthreads_mpi(::Val{:sockets}, rank::Integer, nranks::Integer;
                        nthreads_per_rank = Threads.nthreads(),
                        compact = false,
                        kwargs...)
    idx_in_socket, socketidx = divrem(rank, nsockets()) .+ 1
    idcs = ((idx_in_socket - 1) * nthreads_per_rank + 1):(idx_in_socket * nthreads_per_rank)
    if maximum(idcs) >= ncputhreads_per_socket()[socketidx]
        error("Too many Julia threads / MPI ranks per socket.")
    end
    cpuids = socket(socketidx, idcs; compact)
    pinthreads(cpuids; nthreads = nthreads_per_rank, kwargs...)
    return nothing
end
function pinthreads_mpi(::Val{:numa}, rank::Integer, nranks::Integer;
                        nthreads_per_rank = Threads.nthreads(),
                        compact = false,
                        kwargs...)
    idx_in_numa, numaidx = divrem(rank, nnuma()) .+ 1
    idcs = ((idx_in_numa - 1) * nthreads_per_rank + 1):(idx_in_numa * nthreads_per_rank)
    if maximum(idcs) >= ncputhreads_per_numa()[numaidx]
        error("Too many Julia threads / MPI ranks per memory domain (NUMA).")
    end
    cpuids = numa(numaidx, idcs; compact)
    pinthreads(cpuids; nthreads = nthreads_per_rank, kwargs...)
    return nothing
end
