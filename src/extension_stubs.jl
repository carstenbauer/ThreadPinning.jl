"""
Pin MPI ranks, that is, their respective Julia thread(s), to (subsets of) domains
(e.g. sockets or memory domains).

**Important:** Only works for Julia versions >= 1.9 and if the MPI.jl package is loaded in
the Julia session.
"""
function pinthreads_mpi end
