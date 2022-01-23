# ----------- High-level API -----------
"""
Returns the ID of the CPU on which the calling thread
is currently executing.

See `sched_getcpu` for more information.
"""
getcpuid() = Int(sched_getcpu())

"""
Returns the ID of the CPUs on which the Julia threads
are currently running.

See `getcpuid` for more information.
"""
function getcpuids()
    nt = nthreads()
    cpuids = zeros(Int, nt)
    @threads :static for tid in 1:nt
        cpuids[tid] = getcpuid()
    end
    return cpuids
end

"""
Pin the calling Julia thread to the CPU with id `cpuid`.

For more information see `uv_thread_setaffinity`.
"""
function pinthread(cpuid::Integer; warn::Bool = true)
    warn && _check_environment()
    uv_thread_setaffinity(cpuid)
end

"""
    pinthreads(cpuids::AbstractVector{<:Integer}[; warn])
Pins the first `1:length(cpuids)` Julia threads to the CPUs with ids `cpuids`.
Note that `length(cpuids)` may not be larger than `Threads.nthreads()`.

For more information see `pinthread`.
"""
function pinthreads(cpuids::AbstractVector{<:Integer}; warn::Bool = true)
    warn && _check_environment()
    ncpuids = length(cpuids)
    ncpuids ≤ nthreads() || throw(ArgumentError("length(cpuids) must be ≤ Threads.nthreads()"))
    @threads :static for tid in 1:ncpuids
        pinthread(cpuids[tid]; warn = false)
    end
    return nothing
end

"""
    pinthreads(strategy::Symbol[; nthreads, warn, kwargs...])
Pin the first `1:nthreads` Julia threads according to the given pinning `strategy`.
Per default, `nthreads == Threads.nthreads()`

Allowed strategies:
* `:compact`: pins to the first `1:nthreads` cores
* `:scatter` or `:spread`: pins to all available sockets in an alternating / round robin fashion. To function automatically, Hwloc.jl should be loaded (i.e. `using Hwloc`). Otherwise, we the keyword arguments `nsockets` (default: `2`) and `hyperthreads` (default: `false`) can be used to indicate whether hyperthreads are available on the system (i.e. whether `Sys.CPU_THREADS == 2 * nphysicalcores`).
"""
function pinthreads(strategy::Symbol; nthreads = Threads.nthreads(), warn::Bool = true, kwargs...)
    warn && _check_environment()
    if strategy == :compact
        return _pin_compact(nthreads)
    elseif strategy in (:scatter, :spread)
        return _pin_scatter(nthreads; kwargs...)
    else
        throw(ArgumentError("Unknown pinning strategy."))
    end
end

_pin_compact(nthreads) = pinthreads(0:nthreads-1; warn = false)
function _pin_scatter(nthreads; hyperthreading = false, nsockets = 2, verbose = false, kwargs...)
    verbose && @info("Assuming $nsockets sockets and the ", hyperthreading ? "availability" : "absence", " of hyperthreads.")
    ncpus = Sys.CPU_THREADS
    if !hyperthreading
        cpuids_per_socket = Iterators.partition(0:ncpus-1, ncpus ÷ nsockets)
        cpuids = interweave(cpuids_per_socket...)
    else
        # alternate between sockets but use hyperthreads (i.e. 2 threads per core) only if necessary
        cpuids_per_socket_and_hyper = collect.(Iterators.partition(0:ncpus-1, (ncpus ÷ 2) ÷ nsockets))
        cpuids_per_socket = [reduce(vcat, cpuids_per_socket_and_hyper[s:nsockets:end]) for s in 1:nsockets]
        cpuids = interweave(cpuids_per_socket...)
    end
    pinthreads(@view cpuids[1:nthreads]; warn = false)
    return nothing
end

"""
Print information about Julia threads, e.g. on which CPU-cores they are running.

By default, the visualization will be based on `Sys.CPU_THREADS` only.
If you also load Hwloc.jl (via `using Hwloc`) it will show more detailed information.
"""
function threadinfo()
    # general info
    thread_cpuids = getcpuids()
    # visualize current pinning
    println()
    println("Julia threads: ", Threads.nthreads())
    println("Occupied cores: ", length(unique(thread_cpuids)), "\n")
    _visualize_affinity(; thread_cpuids)
    println("Thread-Core mapping:")
    for (tid, core) in enumerate(thread_cpuids)
        println("  $tid => $core")
        if tid == 10
            println("  ...")
            break
        end
    end
    println()
    return nothing
end

function _visualize_affinity(; thread_cpuids = getcpuids())
    print(" ")
    for puid in 0:Sys.CPU_THREADS-1
        if puid in thread_cpuids
            printstyled(puid, bold = true, underline = false, color = :red)
        else
            print(puid)
        end
        !(puid == Sys.CPU_THREADS - 1) && print(",")
    end
    println()
    # legend
    println()
    printstyled("#", bold = true, underline = false, color = :red)
    print(" = Julia thread")
    println("\n")
    return nothing
end