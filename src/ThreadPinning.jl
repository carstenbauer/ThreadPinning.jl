module ThreadPinning

# imports
using Base.Threads: @threads, nthreads, threadid
using Libdl
using LinearAlgebra
import Random
using DelimitedFiles

# includes
include("utility.jl")
include("sysinfo.jl")
include("lscpu_examples.jl")
include("libs/libc.jl")
include("libs/libuv.jl")
include("libs/libpthread.jl")
include("omp.jl")
include("blas.jl")
include("querying.jl")
include("pinning.jl")
include("threadinfo.jl")
include("latency.jl")

# initialization
function __init__()
    if lowercase(get(ENV, "JULIA_TP_AUTOUPDATE", "true")) != "false"
        update_sysinfo!()
    end

    JULIA_PINTHREADS = get(ENV, "JULIA_PINTHREADS", nothing)
    JULIA_PINTHREADS_PLACES = get(ENV, "JULIA_PINTHREADS_PLACES", nothing)
    if !isnothing(JULIA_PINTHREADS)
        try
            binding = Symbol(lowercase(JULIA_PINTHREADS))
            if !isnothing(JULIA_PINTHREADS_PLACES)
                pinthreads(binding; places = Symbol(lowercase(JULIA_PINTHREADS_PLACES)))
            else
                pinthreads(binding)
            end
        catch err
            @warn("Ignoring unsupported settings:", JULIA_PINTHREADS,
                  JULIA_PINTHREADS_PLACES)
        end
    end
    return nothing
end

# precompile
import SnoopPrecompile
SnoopPrecompile.@precompile_all_calls begin
    sysinfo()
    # threadinfo()
    pinthreads(:compact)
    pinthread(0)
    pinthreads(0:(nthreads() - 1))
    pinthreads(collect(0:(nthreads() - 1)))
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
       cpuids_all,
       CPUThreads,
       Cores,
       Sockets,
       NUMA,
       CompactBind,
       SpreadBind,
       RandomBind,
       CurrentBind
end
