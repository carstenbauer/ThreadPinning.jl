module ThreadPinning

# stdlibs
using Base.Threads: @threads, nthreads, threadid
using Libdl
using LinearAlgebra
using Random
using DelimitedFiles

# system information
Base.@kwdef struct SysInfo
    nsockets::Int = 1
    nnuma::Int = 1
    hyperthreading::Bool = false
    cpuids::Vector{Int} = collect(0:(Sys.CPU_THREADS - 1))
    cpuids_sockets::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    cpuids_numa::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    ishyperthread::Vector{Bool} = fill(false, Sys.CPU_THREADS)
end
function Base.show(io::IO, sysinfo::SysInfo)
    return print(io, "SysInfo()")
end
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, sysinfo::SysInfo)
    summary(io, sysinfo)
    println(io)
    fnames = fieldnames(SysInfo)
    for fname in fnames[1:(end - 1)]
        println(io, "├ $fname: ", getfield(sysinfo, fname))
    end
    print(io, "└ $(fnames[end]): ", getfield(sysinfo, fnames[end]))
    return nothing
end

# constants
const SYSINFO_ATTEMPT = Ref{Bool}(false) # have we yet attempted to gather the sysinfo
const SYSINFO_SUCCESS = Ref{Bool}(false) # have we succeeded in gathering the sysinfo yet
const SYSINFO = Ref{SysInfo}(SysInfo())

# includes
include("utility.jl")
include("lscpu_examples.jl")
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
export sysinfo,
       nsockets,
       nnuma,
       ncputhreads,
       hyperthreading_is_enabled,
       ishyperthread,
       cpuids_per_socket,
       cpuids_per_numa,
       cpuids_all
export threadinfo

end
