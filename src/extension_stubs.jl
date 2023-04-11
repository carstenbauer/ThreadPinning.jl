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
