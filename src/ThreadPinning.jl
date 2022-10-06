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
    # JULIA_TP_AUTOUPDATE = get(ENV, "JULIA_TP_AUTOUPDATE", nothing)
    # autoup_user_optout = !isnothing(JULIA_TP_AUTOUPDATE) && lowercase(JULIA_TP_AUTOUPDATE) == "false"
    # if !autoup_user_optout
    #     update_sysinfo!()
    # end

    JULIA_PIN = get(ENV, "JULIA_PIN", nothing)
    JULIA_PLACES = get(ENV, "JULIA_PLACES", nothing)
    if !isnothing(JULIA_PIN)
        try
            binding = Symbol(lowercase(JULIA_PIN))
            if !isnothing(JULIA_PLACES)
                pinthreads(binding; places = Symbol(lowercase(JULIA_PLACES)))
            else
                pinthreads(binding)
            end
        catch err
            @warn("Ignoring unsupported settings:", JULIA_PIN,
                  JULIA_PLACES)
        end
    end
    return nothing
end

# precompile
# import SnoopPrecompile
# SnoopPrecompile.@precompile_all_calls begin
#     sysinfo()
#     # threadinfo()
#     pinthread(0)
#     pinthreads(0:(nthreads() - 1))
#     pinthreads(collect(0:(nthreads() - 1)))
#     pinthreads(:compact)
#     pinthreads(:spread)
#     pinthreads(:random)
#     pinthreads(:current)
#     pinthreads(:compact; places=Cores())
#     pinthreads(:compact; places=CPUThreads())
#     pinthreads(:spread; places=NUMA())
#     pinthreads(:spread; places=Sockets())
#     getcpuid()
#     getcpuids()
#     nsockets()
#     nnuma()
#     cpuids_all()
#     cpuids_per_socket()
#     cpuids_per_numa()
#     ncputhreads()
#     ncputhreads_per_socket()
#     ncputhreads_per_numa()
#     ncores()
#     ncores_per_socket()
#     ncores_per_numa()
# end

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
