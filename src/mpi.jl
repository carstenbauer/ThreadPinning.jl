"""
    mpi_pinthreads(symbol; compact, kwargs...)

Pin the Julia threads of MPI ranks in a round-robin fashion to specific domains
(e.g. sockets). Supported domains (`symbol`) are `:sockets`, `:numa`, and `:cores`.

When calling this function on all MPI ranks, the Julia threads of the latter will be
distributed in a round-robin fashion among the specified domains and will be pinned to
non-overlapping ranges of CPU-threads within the domains.

A multi-node setup, where MPI ranks are hosted on different nodes, is supported.

If `compact=false` (default), physical cores are occupied before hyperthreads. Otherwise,
CPU-cores - with potentially multiple CPU-threads - are filled up one after another
(compact pinning).

*Example:*

```
using ThreadPinning
using MPI
MPI.Init()
mpi_pinthreads(:sockets)
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


"""
On rank 0, this function returns a vector of named tuples. Each named tuple represents a
MPI rank and has keys `rank`, `localrank`, `node`, and `nodename`.
"""
function mpi_topology end
