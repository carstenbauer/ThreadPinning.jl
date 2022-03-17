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
const HYPERTHREADING = Ref{Union{Nothing, Bool}}(nothing)
const NSOCKETS = Ref{Union{Nothing, Int}}(nothing)
const CPUIDS = Ref{Union{Nothing, Vector{Vector{Int}}}}(nothing)
const ISHYPERTHREAD = Ref{Union{Nothing, Vector{Bool}}}(nothing)

# includes
include("utility.jl")
include("libc.jl")
include("libuv.jl")
include("libpthread.jl")
include("api.jl")
export getcpuid, getcpuids, pinthread, pinthreads, threadinfo, @tspawnat

include("Core2CoreLatency/Core2CoreLatency.jl")
using .Core2CoreLatency
include("latency.jl")

function __init__()
    @require Hwloc = "0e44f5e4-bd66-52a0-8798-143a42290a1d" include("hwloc.jl")

    @static if !Sys.islinux()
        @warn(
            "ThreadPinning.jl currently only supports Linux. Don't expect anything to work!"
        )
    else
        if !gather_sysinfo_lscpu()
            # couldn't gather sysinfo -> use defaults
            NSOCKETS[] = 1
            HYPERTHREADING[] = false
            CPUIDS[] = Vector{Int}[collect(0:Sys.CPU_THREADS-1)]
            ISHYPERTHREAD[] = fill(false, Sys.CPU_THREADS)
        end
    end
end

end
