"""
Returns the ID of the CPU thread on which the calling thread
(or the thread with the given ID) is currently running
"""
function getcpuid end

"""
Returns the IDs of the CPU-threads on which the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to specify a specific
thread pool.
"""
function getcpuids end

"""
Returns the ID (starting at zero) of the NUMA node corresponding to the CPU thread on which
the calling thread is currently running. A `threadid` may be provided to consider a Julia
thread that is different from the calling one.
"""
function getnumanode end

"""
Returns the IDs (starting at zero) of the NUMA nodes corresponding to the CPU threads on which
the Julia threads are currently running.

The keyword argument `threadpool` (default: `:default`) may be used to consider only those
Julia threads that belong to a specific thread pool.
"""
function getnumanodes end

"""
$(SIGNATURES)Print the affinity mask of a Julia thread.
"""
function print_affinity_mask end

"""
$(SIGNATURES)Get the affinity mask of the given Julia Thread
"""
function getaffinity end

"""
Returns `true` if the thread is pinned, i.e. if it has an affinity mask that comprises a single CPU-thread.
"""
function ispinned end

"""
Check whether simultaneous multithreading (SMT) / "hyperthreading" is enabled.
"""
function hyperthreading_is_enabled end

"$(SIGNATURES)Check whether the given CPU-thread is a hyperthread (i.e. the second
CPU-thread within a CPU-core)."
function ishyperthread end

"Number of CPU-threads"
function ncputhreads end

"Number of cores (i.e. excluding hyperthreads)"
function ncores end

"Number of NUMA nodes"
function nnuma end

"Number of CPU sockets"
function nsockets end

"Number of CPU-threads per core"
function ncputhreads_per_core end

"Number of CPU-threads per NUMA domain"
function ncputhreads_per_numa end

"Number of CPU-threads per socket"
function ncputhreads_per_socket end

"Number of CPU-cores per NUMA domain"
function ncores_per_numa end

"Number of CPU-cores per socket"
function ncores_per_socket end

"Returns a `Vector{Int}` which lists all valid CPUIDs. There is no guarantee about the
order except that it is the same as in `lscpu`."
function cpuids_all end

"Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
physical cores"
function cpuids_per_core end

"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
NUMA domains. Within each memory domain, physical cores come first. Set `compact=true` to
get compact ordering instead.
"""
function cpuids_per_numa end

"""
$(SIGNATURES)
Returns a `Vector{Vector{Int}}` which indicates the CPUIDs associated with the available
CPU sockets. Within each socket, physical cores come first. Set `compact=true` to get
compact ordering instead.
"""
function cpuids_per_socket end

"""
$(SIGNATURES)
Returns a `Vector{Int}` which indicates the CPUIDs associated with the available node.
Physical cores come first. Set `compact=true` to get compact ordering.
"""
function cpuids_per_node end

"""
$(SIGNATURES)
Represents the CPU ID domain of core `i` (logical index, starts at 1). Uses compact ordering
by default. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function core end

"""
$(SIGNATURES)
Represents the CPU ID domain of NUMA/memory domain `i` (logical index, starts at 1). By
default, cores will be used first and hyperthreads will only be used if necessary. Provide
`compact=true` to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function numa end

"""
$(SIGNATURES)
Represents the CPU ID domain of socket `i` (logical index, starts at 1). By default, cores
will be used first and hyperthreads will only be used if necessary. Provide `compact=true`
to get compact ordering instead. Set `shuffle=true` to randomize.

Optional second argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function socket end

"""
$(SIGNATURES)
Represents the CPU ID domain of the entire node/system. By default, cores will be used first
and hyperthreads will only be used if necessary. Provide `compact=true` to get compact
ordering instead. Set `shuffle=true` to randomize. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function node end

"""
$(SIGNATURES)
Represents the CPU IDs of the system as obtained by a round-robin scattering
between sockets. By default, within each socket, cores will be used first and hyperthreads
will only be used if necessary. Provide `compact=true` to get compact ordering within each
socket. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function sockets end

"""
$(SIGNATURES)
Represents the CPU IDs of the system as obtained by a round-robin scattering
between NUMA/memory domain. By default, within each memory domain, cores will be used first
and hyperthreads will only be used if necessary. Provide `compact=true` to get compact
ordering within each memory domain. Set `shuffle=true` to randomize.

Optional first argument: Logical indices to select a subset of the domain.

To be used as input argument for [`pinthreads`](@ref). What it actually returns is an
implementation detail!
"""
function numas end
