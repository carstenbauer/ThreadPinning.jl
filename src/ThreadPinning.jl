module ThreadPinning

# imports
# using Base.Threads: @threads, nthreads, threadid
# using Libdl: Libdl
# using LinearAlgebra: BLAS, rank
# using Random: Random
# using DelimitedFiles: readdlm
using DocStringExtensions: SIGNATURES, TYPEDSIGNATURES

const DEFAULT_IO = Ref{Union{IO, Nothing}}(nothing)
getstdout() = something(DEFAULT_IO[], stdout)

# includes
include("public_macro.jl")
include("utility.jl")
include("slurm.jl")
include("threadinfo.jl")
include("querying.jl")
@static if Sys.islinux()
    include("pinning.jl")
    # include("pinning_mpi.jl")
    # include("likwid-pin.jl")
    # include("mkl.jl")
    # include("openblas.jl")
else
    # make core pinning functions no-ops
    pinthreads(args...; kwargs...) = nothing
    pinthread(args...; kwargs...) = nothing
    unpinthreads(args...; kwargs...) = nothing
    unpinthread(args...; kwargs...) = nothing
    setaffinity(args...; kwargs...) = nothing
    setaffinity_cpuids(args...; kwargs...) = nothing
    with_pinthreads(f, args...; kwargs...) = f()
    # pinthreads_likwidpin(args...; kwargs...) = nothing
    # pinthreads_mpi(args...; kwargs...) = nothing
end
# include("preferences.jl")

# function _try_get_autoupdate()
#     try
#         x = Prefs.get_autoupdate()
#         if isnothing(x)
#             return true # default
#         else
#             return x
#         end
#     catch err
#         @warn("Couldn't parse autoupdate preference \"$x\" (not a boolean?). Falling "*
#         "back to default (true).")
#         return true # default
#     end
# end

# const AUTOUPDATE = _try_get_autoupdate() # compile-time preference

# function maybe_autopin()
#     JULIA_PIN = get(ENV, "JULIA_PIN", Prefs.get_pin())
#     JULIA_LIKWID_PIN = get(ENV, "JULIA_LIKWID_PIN", Prefs.get_likwidpin())
#     if !isnothing(JULIA_PIN)
#         @debug "Autopinning" JULIA_PIN
#         try
#             str = startswith(JULIA_PIN, ':') ? JULIA_PIN[2:end] : JULIA_PIN
#             pinthreads(Symbol(lowercase(str)))
#         catch err
#             error("Unsupported value for environment variable JULIA_PIN: ", JULIA_PIN)
#         end
#     elseif !isnothing(JULIA_LIKWID_PIN)
#         @debug "Autopinning" JULIA_LIKWID_PIN
#         try
#             pinthreads_likwidpin(JULIA_LIKWID_PIN)
#         catch err
#             error("Unsupported value for environment variable JULIA_PIN: ", JULIA_PIN)
#         end
#     end
#     return
# end

# initialization
# function __init__()
#     @static if Sys.islinux()
#         set_initial_affinity_mask()
#         forget_pin_attempts()
#         if AUTOUPDATE
#             update_sysinfo!(; fromscratch = true)
#         end
#         maybe_autopin()
#     else
#         os_warning = Prefs.get_os_warning()
#         if isnothing(os_warning) || os_warning
#             @warn("Operating system not supported by ThreadPinning.jl."*
#                   " Functions like `pinthreads` will be no-ops!\n"*
#                   "(Hide this warning via `ThreadPinning.Prefs.set_os_warning(false)`.)")
#         end
#     end
#     return
# end

# exports
## threadinfo
export threadinfo

## querying
export getcpuid, getcpuids, getaffinity, getnumanode, getnumanodes
export core, numa, socket, node, cores, numas, sockets
export printaffinity, printaffinities, visualize_affinity
export ispinned, hyperthreading_is_enabled, ishyperthread
export ncputhreads, ncores, nnuma, nsockets
@public cpuids

## pinning
export pinthread, pinthreads, with_pinthreads, unpinthread, unpinthreads
export setaffinity, setaffinity_cpuids

## re-export
using StableTasks: @spawnat
export @spawnat

# precompile
import PrecompileTools
PrecompileTools.@compile_workload begin
    try
        redirect_stdout(Base.DevNull()) do
            threadinfo()
            threadinfo(; slurm = true)
            threadinfo(; groupby = :numa)
            threadinfo(; compact = false)

            @static if Sys.islinux()
                c = getcpuid()
                pinthread(c; warn = false)
                pinthreads([c]; warn = false)
                pinthreads(c:c; warn = false)
                pinthreads(:compact; nthreads = 1, warn = false)
                pinthreads(:cores; nthreads = 1, warn = false)
                pinthreads(:random; nthreads = 1, warn = false)
                pinthreads(:current; nthreads = 1, warn = false)
                if nsockets() > 1
                    pinthreads(:sockets; nthreads = 1, warn = false)
                end
                if nnuma() > 1
                    pinthreads(:numa; nthreads = 1, warn = false)
                end
                setaffinity_cpuids([c])
                getcpuid()
                getcpuids()
                getnumanode()
                getnumanodes()
                nsockets()
                nnuma()
                cpuids()
                # cpuids_per_socket()
                # cpuids_per_numa()
                # cpuids_per_node()
                # cpuids_per_core()
                ncputhreads()
                # ncputhreads_per_socket()
                # ncputhreads_per_numa()
                # ncputhreads_per_core()
                ncores()
                # ncores_per_socket()
                # ncores_per_numa()
                socket(1, 1:1)
                socket(1, [1])
                numa(1, 1:1)
                numa(1, [1])
                node(1:1)
                node([1])
                core(1, [1])
                sockets()
                numas()
                ispinned()
                ishyperthread(c)
                hyperthreading_is_enabled()
                unpinthread()
                unpinthreads()
                printaffinity()
                printaffinities()
                visualize_affinity()
            end
        end
    catch err
    end
end

end
