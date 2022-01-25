module ThreadPinning

# stdlibs
using Base.Threads: @threads, nthreads
using Libdl
using LinearAlgebra
using Random

# packages
using Requires

# includes
include("helper.jl")
include("libc.jl")
include("libuv.jl")
include("libpthread.jl")
include("api.jl")
export getcpuid, getcpuids, pinthread, pinthreads, threadinfo

function __init__()
    @require Hwloc = "0e44f5e4-bd66-52a0-8798-143a42290a1d" include("hwloc.jl")

    @static if !Sys.islinux()
        @warn("ThreadPinning.jl currently only supports Linux. Don't expect anything to work!")
    end
end


end
