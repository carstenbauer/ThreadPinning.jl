module DistributedExt

import ThreadPinning: ThreadPinning
using Distributed: Distributed

@static if Sys.islinux()
    include("distributed_querying.jl")
    include("distributed_pinning.jl")
end

end # module
