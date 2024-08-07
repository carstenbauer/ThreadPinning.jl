module MPIExt

import ThreadPinning: ThreadPinning
using MPI: MPI

@static if Sys.islinux()
    include("mpi_querying.jl")
    include("mpi_pinning.jl")
end

end # module
