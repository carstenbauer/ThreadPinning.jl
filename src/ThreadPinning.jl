module ThreadPinning

# imports
using Base.Threads: @threads, nthreads, threadid
using Libdl
using LinearAlgebra
import Random
using DelimitedFiles
using DocStringExtensions

const DEFAULT_IO = Ref{Union{IO, Nothing}}(nothing)
getstdout() = something(DEFAULT_IO[], stdout)

# includes
include("utility.jl")
@static if Sys.islinux()
    include("sysinfo.jl")
    include("lscpu_examples.jl")
    include("libs/libc.jl")
    include("libs/libuv.jl")
    include("libs/libpthread.jl")
    include("querying.jl")
    include("slurm.jl")
    include("pinning.jl")
    include("pinning_mpi.jl")
    include("setaffinity.jl")
    include("likwid-pin.jl")
    include("mkl.jl")
    include("openblas.jl")
    include("threadinfo.jl")
    include("latency.jl")
else
    pinthreads(args...; kwargs...) = nothing
    pinthread(args...; kwargs...) = nothing
    setaffinity(args...; kwargs...) = nothing
    pinthreads_likwidpin(args...; kwargs...) = nothing
    pinthreads_mpi(args...; kwargs...) = nothing
end
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
        @warn("Couldn't parse autoupdate preference \"$x\" (not a boolean?). Falling "*
              "back to default (true).")
        return true # default
    end
end

const AUTOUPDATE = _try_get_autoupdate() # compile-time preference

function maybe_autopin()
    JULIA_PIN = get(ENV, "JULIA_PIN", Prefs.get_pin())
    JULIA_LIKWID_PIN = get(ENV, "JULIA_LIKWID_PIN", Prefs.get_likwidpin())
    if !isnothing(JULIA_PIN)
        @debug "Autopinning" JULIA_PIN
        try
            str = startswith(JULIA_PIN, ':') ? JULIA_PIN[2:end] : JULIA_PIN
            pinthreads(Symbol(lowercase(str)))
        catch err
            error("Unsupported value for environment variable JULIA_PIN: ", JULIA_PIN)
        end
    elseif !isnothing(JULIA_LIKWID_PIN)
        @debug "Autopinning" JULIA_LIKWID_PIN
        try
            pinthreads_likwidpin(JULIA_LIKWID_PIN)
        catch err
            error("Unsupported value for environment variable JULIA_PIN: ", JULIA_PIN)
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
        os_warning = Prefs.get_os_warning()
        if isnothing(os_warning) || parse(Bool, os_warning)
            @warn("Operating system not supported by ThreadPinning.jl."*
                  " Functions like `pinthreads` will be no-ops!")
        end
    end
    return nothing
end

# precompile
import PrecompileTools
PrecompileTools.@compile_workload begin @static if Sys.islinux()
    ThreadPinning.lscpu2sysinfo(LSCPU_STRING)
    update_sysinfo!()
    lscpu_string()
    pinthread(0)
    pinthreads(0:(nthreads() - 1))
    pinthreads(collect(0:(nthreads() - 1)))
    pinthreads(:compact; nthreads = 1)
    pinthreads(:cores; nthreads = 1)
    pinthreads(:sockets; nthreads = 1)
    pinthreads(:sockets; nthreads = 1, compact = true)
    pinthreads(:numa; nthreads = 1)
    pinthreads(:numa; nthreads = 1, compact = true)
    pinthreads(:random; nthreads = 1)
    pinthreads(:current; nthreads = 1)
    setaffinity(node(1:2))
    getcpuid()
    getcpuids()
    nsockets()
    nnuma()
    cpuids_all()
    cpuids_per_socket()
    cpuids_per_numa()
    cpuids_per_node()
    cpuids_per_core()
    ncputhreads()
    ncputhreads_per_socket()
    ncputhreads_per_numa()
    ncputhreads_per_core()
    ncores()
    ncores_per_socket()
    ncores_per_numa()
    socket(1, 1:1)
    socket(1, [1])
    numa(1, 1:1)
    numa(1, [1])
    node(1:1)
    node([1])
    core(1, [1])
    sockets()
    numas()
end end

# exports
export threadinfo,
       pinthreads,
       pinthreads_likwidpin,
       pinthreads_mpi,
       pinthread,
       setaffinity,
       getcpuids,
       getcpuid,
       unpinthreads,
       unpinthread,
       @tspawnat,
       print_affinity_mask,
       print_affinity_masks,
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
       node,
       socket,
       sockets,
       numa,
       numas,
       core
#    cores
end
