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
include("likwid-pin.jl")
include("threadinfo.jl")
include("latency.jl")
include("preferences.jl")

function _try_get_autoupdate()
    try
        x = Prefs.get_autoupdate()
        if isnothing(x)
            return true # default
        else
            return x
        end
    catch err
        @warn("Couldn't parse autoupdate preference \"$x\" (not a boolean?). Falling back to default (true).")
        return true # default
    end
end

const AUTOUPDATE = _try_get_autoupdate() # compile-time preference

function maybe_autopin()
    JULIA_PIN = get(ENV, "JULIA_PIN", nothing)
    JULIA_PLACES = get(ENV, "JULIA_PLACES", nothing)
    if !isnothing(JULIA_PIN)
        try
            pinning = Symbol(lowercase(JULIA_PIN))
            if !isnothing(JULIA_PLACES)
                pinthreads(pinning; places = Symbol(lowercase(JULIA_PLACES)))
            else
                pinthreads(pinning)
            end
        catch err
            @warn("Ignoring unsupported settings:", JULIA_PIN,
                  JULIA_PLACES)
        end
    else
        pinning = Prefs.get_pinning()
        if !isnothing(pinning)
            places = Prefs.get_places()
            if !isnothing(places)
                pinthreads(pinning; places)
            else
                pinthreads(pinning)
            end
        end
    end
    return nothing
end

# initialization
function __init__()
    @static if Sys.islinux()
        forget_pin_attempts()
        if AUTOUPDATE
            update_sysinfo!(; fromscratch = true)
        end
        maybe_autopin()
    else
        error("Operating system not supported. ThreadPinning.jl currently only supports Linux.")
    end
    return nothing
end

# precompile
import SnoopPrecompile
SnoopPrecompile.@precompile_all_calls begin @static if Sys.islinux()
    ThreadPinning.lscpu2sysinfo(LSCPU_STRING)
    update_sysinfo!()
    lscpu_string()
    sysinfo()
    pinthread(0)
    pinthreads(0:(nthreads() - 1))
    pinthreads(collect(0:(nthreads() - 1)))
    pinthreads(:compact; nthreads = 1)
    pinthreads(:spread; nthreads = 1)
    pinthreads(:random; nthreads = 1)
    pinthreads(:current; nthreads = 1)
    pinthreads(:compact; places = Cores(), nthreads = 1)
    pinthreads(:compact; places = CPUThreads(), nthreads = 1)
    pinthreads(:spread; places = NUMA(), nthreads = 1)
    pinthreads(:spread; places = Sockets(), nthreads = 1)
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
end end

# exports
export threadinfo,
       pinthreads,
       pinthreads_likwidpin,
       pinthread,
       maybe_pinthreads,
       getcpuids,
       getcpuid,
       unpinthreads,
       unpinthread,
       @tspawnat,
       sysinfo,
       ncputhreads,
       ncores,
       nnuma,
       nsockets,
       ncputhreads_per_core,
       ncputhreads_per_numa,
       ncputhreads_per_socket,
       ncores_per_numa,
       ncores_per_socket,
       hyperthreading_is_enabled,
       ishyperthread,
       cpuids_all,
       cpuids_per_core,
       cpuids_per_numa,
       cpuids_per_socket,
       cpuids_per_node,
       CPUThreads,
       Cores,
       Sockets,
       NUMA,
       CompactBind,
       SpreadBind,
       RandomBind,
       CurrentBind
end
