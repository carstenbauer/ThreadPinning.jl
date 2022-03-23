module ThreadPinning

# stdlibs
using Base.Threads: @threads, nthreads
using Libdl
using LinearAlgebra
using Random
using DelimitedFiles

# system information
Base.@kwdef struct SysInfo
    nsockets::Int = 1
    nnuma::Int = 1
    hyperthreading::Bool = false
    cpuids_sockets::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    cpuids_numa::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    ishyperthread::Vector{Bool} = fill(false, Sys.CPU_THREADS)
end
const SYSINFO_INITIALIZED = Ref{Bool}(false)
const SYSINFO = Ref{SysInfo}(SysInfo())

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
export systeminfo,
    nsockets,
    nnuma,
    hyperthreading_is_enabled,
    ishyperthread,
    cpuids_per_socket,
    cpuids_per_numa
export threadinfo

function __init__()
    @static if !Sys.islinux()
        @warn(
            "ThreadPinning.jl currently only supports Linux. Don't expect anything to work!"
        )
    else
        if !maybe_init_sysinfo()
            @warn(
                "Couldn't gather system information. Perhaps `lscpu` isn't available? Not all features will work (optimally)."
            )
        end
    end
    return nothing
end

end
