"""
    distributed_pinthreads(symbol;
        include_master = false,
        compact = false,
        nthreads_per_proc = Threads.nthreads(),
        kwargs...)

Pin the Julia threads of Julia workers in a round-robin fashion to specific domains
(e.g. sockets). Supported domains (`symbol`) are `:sockets`, `:numa`, and `:cores`.

When calling this function, the Julia threads of all Julia workers will be
distributed in a round-robin fashion among the specified domains and will be pinned to
non-overlapping ranges of CPU-threads within the domains.

A multi-node setup, where Julia workers are hosted on different nodes, is supported.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be
pinned as well.

If `compact=false` (default), physical cores are occupied before hyperthreads. Otherwise,
CPU-cores - with potentially multiple CPU-threads - are filled up one after another
(compact pinning).

*Example:*

```
using Distributed
addprocs(3)
@everywhere using ThreadPinning
distributed_pinthreads(:sockets)
```
"""
function distributed_pinthreads end

"""
Unpin all threads on all Julia workers.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be
unpinned as well.
"""
function distributed_unpinthreads end

"""
Returns a `Dict{Int, Vector{Int}}` where the keys are the pids of the Julia workers and
the values are the CPU IDs of the CPU-threads that are currently
running the Julia threads of the worker.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be included.
"""
function distributed_getcpuids end

"""
Returns a `Dict{Int, String}` where the keys are the pids of the Julia workers and the
values are the hostnames of the nodes that are currently hosting the respective workers.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be included.
"""
function distributed_gethostnames end

"""
Returns a `Dict{Int, Vector{Bool}}` where the keys are the pids of the Julia workers and
the values are the results of `ThreadPinning.ispinned` evaluated for all Julia threads of
a worker.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be included.
"""
function distributed_getispinned end

"""
Returns a vector of named tuples. Each named tuple represents a
Julia worker and has keys `pid`, `localid`, `node`, and `nodename`.

If `include_master=true`, the master process (`Distributed.myid() == 1`) will be included.
"""
function distributed_topology end

function _distributed_pinyourself end
