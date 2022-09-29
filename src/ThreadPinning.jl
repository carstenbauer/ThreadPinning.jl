module ThreadPinning

# imports
using Base.Threads: @threads, nthreads, threadid
using Libdl
using LinearAlgebra
using Random
using DelimitedFiles

# includes
include("sysinfo.jl")
include("utility.jl")
include("lscpu_examples.jl")
include("libs/libc.jl")
include("libs/libuv.jl")
include("libs/libpthread.jl")
include("blas.jl")
include("querying.jl")
include("pinning.jl")
include("threadinfo.jl")
include("latency.jl")

# initialization
function __init__()
    update_sysinfo!()
end

# precompile
import SnoopPrecompile
SnoopPrecompile.@precompile_all_calls begin
    sysinfo()
    threadinfo()
    pinthreads(:compact)
    pinthread(0)
    pinthreads(0:(Threads.nthreads() - 1))
    pinthreads(collect(0:(Threads.nthreads() - 1)))
    getcpuid()
    getcpuids()
    nsockets()
    nnuma()
    cpuids_all()
    cpuids_per_socket()
    cpuids_per_numa()
    ncputhreads()
    ncputhreads_per_socket()
    ncputhreads_per_numa()
    ncores()
    ncores_per_socket()
    ncores_per_numa()
end

# exports
export threadinfo,
       pinthreads,
       pinthread,
       getcpuids,
       getcpuid,
       @tspawnat,
       sysinfo,
       nsockets,
       nnuma,
       ncputhreads,
       ncputhreads_per_numa,
       ncputhreads_per_socket,
       ncores,
       ncores_per_numa,
       ncores_per_socket,
       hyperthreading_is_enabled,
       ishyperthread,
       cpuids_per_socket,
       cpuids_per_numa,
       cpuids_all
end
