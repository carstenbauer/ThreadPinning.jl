module ThreadPinning

const DEFAULT_IO = Ref{Union{IO, Nothing}}(nothing)
getstdout() = something(DEFAULT_IO[], stdout)

# includes
include("public_macro.jl")
include("utility.jl")
include("faking.jl")
include("slurm.jl")
include("threadinfo.jl")
include("querying.jl")
include("mkl.jl")
@static if Sys.islinux()
    include("pinning.jl")
    include("mpi.jl")
    include("likwid-pin.jl")
else
    # make core pinning functions no-ops
    pinthreads(args...; kwargs...) = nothing
    pinthread(args...; kwargs...) = nothing
    unpinthreads(args...; kwargs...) = nothing
    unpinthread(args...; kwargs...) = nothing
    setaffinity(args...; kwargs...) = nothing
    setaffinity_cpuids(args...; kwargs...) = nothing
    with_pinthreads(f, args...; kwargs...) = f()
    pinthreads_likwidpin(args...; kwargs...) = nothing
    pinthreads_mpi(args...; kwargs...) = nothing
    openblas_pinthreads(args...; kwargs...) = nothing
    openblas_pinthread(args...; kwargs...) = nothing
    openblas_unpinthreads(args...; kwargs...) = nothing
    openblas_unpinthread(args...; kwargs...) = nothing
    openblas_setaffinity(args...; kwargs...) = nothing
    openblas_setaffinity_cpuids(args...; kwargs...) = nothing
end

# exports
## threadinfo
export threadinfo

## querying
export getcpuid, getcpuids, getaffinity, getnumanode, getnumanodes
export core, numa, socket, node, cores, numas, sockets
export printaffinity, printaffinities, visualize_affinity
export ispinned, hyperthreading_is_enabled, ishyperthread, isefficiencycore
export ncputhreads, ncores, nnuma, nsockets, ncorekinds, nsmt
export openblas_getaffinity, openblas_getcpuid, openblas_getcpuids,
       openblas_ispinned, openblas_printaffinity, openblas_printaffinities
@public cpuids, id, cpuid

## pinning
export pinthread, pinthreads, with_pinthreads, unpinthread, unpinthreads
export setaffinity, setaffinity_cpuids
export pinthreads_likwidpin, likwidpin_domains, likwidpin_to_cpuids
export pinthreads_mpi
export openblas_setaffinity, openblas_setaffinity_cpuids,
       openblas_pinthread, openblas_pinthreads,
       openblas_unpinthread, openblas_unpinthreads

## re-export
using StableTasks: @spawnat, @spawn, @fetch, @fetchfrom
@public @spawnat, @spawn, @fetch, @fetchfrom

using ThreadPinningCore: threadids
@public threadids

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
                ncputhreads()
                # ncputhreads_per_socket()
                # ncputhreads_per_numa()
                # ncputhreads_per_core()
                # ncores_per_socket()
                # ncores_per_numa()
                ncores()
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
                # openblas
                openblas_pinthread(c; threadid = 1)
                openblas_pinthreads([c])
                openblas_pinthreads(:cores)
                openblas_unpinthread(; threadid = 1)
                openblas_unpinthreads()
                openblas_printaffinity()
                openblas_printaffinities()
            end
        end
    catch err
    end
end

end
