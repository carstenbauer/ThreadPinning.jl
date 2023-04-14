"""
Pin MPI ranks, that is, their respective Julia thread(s), to (subsets of) hardware domains
(e.g. sockets or memory domains). This function is idential to [`pinthreads_hybrid`](@ref)
but automatically queries the MPI rank of the calling process and sets `proc` accordingly.

The keyword argument `comm` (default `MPI.COMM_WORLD`) can be used to specify the MPI
communicator.

**Important:** Only works for Julia versions >= 1.9 and if the MPI.jl package is loaded in
the Julia session.
"""
function pinthreads_mpi end

"""
Query the IDs of the CPU-threads currently used by the Julia threads on all MPI ranks.
Returns a dictionary with "rank => cpuids" structure.

The keyword argument `comm` can be used to specify the MPI communicator (default `MPI.COMM_WORLD`).

**Important:** Only works for Julia versions >= 1.9 and if the MPI.jl package is loaded in
the Julia session.
"""
function getcpuids_mpi end
