module ThreadPinning

# stdlibs
using Base.Threads: @threads, nthreads
using Libdl
using LinearAlgebra
using Random
using DelimitedFiles

# packages
using Requires

# constants (with defaults)
const HYPERTHREADING = Ref{Union{Nothing,Bool}}(nothing)
const NSOCKETS = Ref{Union{Nothing,Int}}(nothing)
const CPUIDS = Ref{Union{Nothing,Vector{Vector{Int}}}}(nothing)
const ISHYPERTHREAD = Ref{Union{Nothing,Vector{Bool}}}(nothing)

# includes
include("utility.jl")
include("libs/libc.jl")
include("libs/libuv.jl")
include("libs/libpthread.jl")
include("blas.jl")
include("querying.jl")
include("pinning.jl")
include("threadinfo.jl")
include("Core2CoreLatency/Core2CoreLatency.jl")
using .Core2CoreLatency
include("latency.jl")
export getcpuid, getcpuids, pinthread, pinthreads, threadinfo, @tspawnat
export hyperthreading_is_enabled, ishyperthread, nsockets, cpuids_per_socket
export threadinfo

function __init__()
    @static if !Sys.islinux()
        @warn(
            "ThreadPinning.jl currently only supports Linux. Don't expect anything to work!"
        )
    else
        if !gather_sysinfo_lscpu()
            # couldn't gather sysinfo -> use defaults
            NSOCKETS[] = 1
            HYPERTHREADING[] = false
            CPUIDS[] = Vector{Int}[collect(0:(Sys.CPU_THREADS - 1))]
            ISHYPERTHREAD[] = fill(false, Sys.CPU_THREADS)
        end
    end
end

end
