module MPIExt

import ThreadPinning: ThreadPinning
using MPI: MPI

# function ThreadPinning.pinthreads_mpi(symb::Symbol, args...; comm = MPI.COMM_WORLD,
#                                       kwargs...)
#     rank = MPI.Comm_rank(comm)
#     ThreadPinning.pinthreads_hybrid(symb, rank + 1)
# end

end # module
