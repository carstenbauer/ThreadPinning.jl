"""
    mpi_pinthreads(symbol, rank, nranks; nthreads_per_rank, compact, kwargs...)

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
mpi_pinthreads(:sockets, rank, nranks)
```
"""
function mpi_pinthreads end

"""
On rank 0, this function returns a `Dict{Int, Vector{Int}}` where the keys
are the MPI rank ids and the values are the CPU IDs of the CPU-threads that are currently
running the Julia threads of the MPI rank. Returns `nothing` on all other ranks.
"""
function mpi_getcpuids end

"""
On rank 0, this function returns a `Dict{Int, String}` where the keys
are the MPI rank ids and the values are the hostnames of the nodes that are currently
hosting the respective MPI ranks. Returns `nothing` on all other ranks.
"""
function mpi_gethostnames end

"""
Returns a node-local rank id (starts at zero). Nodes are identified based on their
hostnames (`gethostname`). On each node, ranks are ordered based on their global rank id.
"""
function mpi_getlocalrank end
