# ----------- High-level API -----------
"""
    @tspawnat tid -> task
Mimics `Base.Threads.@spawn`, but assigns the task to thread `tid` (with `sticky = true`).
# Example
```julia
julia> t = @tspawnat 4 Threads.threadid()
Task (runnable) @0x0000000010743c70
julia> fetch(t)
4
```
"""
macro tspawnat(thrdid, expr)
    # Copied from ThreadPools.jl with the change task.sticky = false -> true
    # https://github.com/tro3/ThreadPools.jl/blob/c2c99a260277c918e2a9289819106dd38625f418/src/macros.jl#L244
    letargs = Base._lift_one_interp!(expr)

    thunk = esc(:(() -> ($expr)))
    var = esc(Base.sync_varname)
    tid = esc(thrdid)
    quote
        if $tid < 1 || $tid > Threads.nthreads()
            throw(AssertionError("@tspawnat thread assignment ($($tid)) must be between 1 and Threads.nthreads() (1:$(Threads.nthreads()))"))
        end
        let $(letargs...)
            local task = Task($thunk)
            task.sticky = true
            ccall(:jl_set_task_tid, Cvoid, (Any, Cint), task, $tid - 1)
            if $(Expr(:islocal, var))
                put!($var, task)
            end
            schedule(task)
            task
        end
    end
end

"""
Returns the ID of the CPU on which the calling thread
is currently executing.

See `sched_getcpu` for more information.
"""
getcpuid() = Int(sched_getcpu())

"""
Returns the ID of the CPU on which the given Julia thread
(`threadid`) is currently executing.
"""
getcpuid(threadid::Integer) = fetch(@tspawnat threadid getcpuid())

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
    pinthread(cpuid::Integer; warn::Bool = true)

Pin the calling Julia thread to the CPU with id `cpuid`.
"""
function pinthread(cpuid::Integer; warn::Bool = true)
    if warn
        (0 ≤ cpuid ≤ Sys.CPU_THREADS - 1) || throw(ArgumentError("cpuid is out of bounds (0 ≤ cpuid ≤ Sys.CPU_THREADS - 1)."))
        _check_environment()
    end
    uv_thread_setaffinity(cpuid)
end

"""
    pinthread(threadid::Integer, cpuid::Integer; kwargs...)

Pin the given Julia thread (`threadid`) to the CPU with ID `cpuid`.
"""
function pinthread(threadid::Integer, cpuid::Integer; kwargs...)
    fetch(@tspawnat threadid pinthread(cpuid; kwargs...))
    return nothing
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
    (minimum(cpuids) ≥ 0 && maximum(cpuids) ≤ Sys.CPU_THREADS - 1) || throw(ArgumentError("All cpuids must be ≤ Sys.CPU_THREADS-1 and ≥ 0."))
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
* `:compact`: pins to the first `0:nthreads-1` cores
* `:scatter` or `:spread`: pins to all available sockets in an alternating / round robin fashion. To function automatically, Hwloc.jl should be loaded (i.e. `using Hwloc`). Otherwise, we the keyword arguments `nsockets` (default: `2`) and `hyperthreads` (default: `false`) can be used to indicate whether hyperthreads are available on the system (i.e. whether `Sys.CPU_THREADS == 2 * nphysicalcores`).
* `:random` or `:rand`: pins threads to random cores (ensures that no core is double occupied).
* `:halfcompact`: pins to the first `0:2:2*nthreads-1` cores
"""
function pinthreads(strategy::Symbol; nthreads = Threads.nthreads(), warn::Bool = true, kwargs...)
    warn && _check_environment()
    if strategy == :compact
        return _pin_compact(nthreads)
    elseif strategy in (:scatter, :spread)
        return _pin_scatter(nthreads; kwargs...)
    elseif strategy in (:rand, :random)
        return _pin_random(nthreads)
    elseif strategy == :halfcompact
        return _pin_halfcompact(nthreads)
    else
        throw(ArgumentError("Unknown pinning strategy."))
    end
end

function _pin_random(nthreads)
    cpuids = shuffle!(collect(1:Sys.CPU_THREADS))
    pinthreads(@view(cpuids[1:nthreads]); warn = false)
end
_pin_compact(nthreads) = pinthreads(0:nthreads-1; warn = false)
_pin_halfcompact(nthreads) = pinthreads(0:2:2*nthreads-1; warn = false)
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

Keyword arguments:
* `color` (default: `true`): Toggle between colored and black-and-white output.
* `blocksize` (default: `32`): Wrap to a new line after `blocksize` many cores.
* `ht`: If true, we highlight virtual cores associated with hyperthreads in the `color=true` output. By default, we try to automatically figure out whether hypterthreading is enabled.
* `blas` (default: `false`): Show information about BLAS threads as well.
* `hints` (default: `false`): Give some hints about how to improve the threading related settings.
"""
function threadinfo(; blas = false, hints = false, color = true, kwargs...)
    # general info
    jlthreads = Threads.nthreads()
    thread_cpuids = getcpuids()
    occupied_cores = length(unique(thread_cpuids))
    cores = Sys.CPU_THREADS
    # visualize current pinning
    println()
    _visualize_affinity(; thread_cpuids, color, kwargs...)
    print("Julia threads: ")
    if color
        printstyled(jlthreads, "\n", color = jlthreads > cores ? :red : :green)
    else
        printstyled(jlthreads, jlthreads > cores ? "(!)" : "", "\n")
    end
    print("├ Occupied cores: ")
    if color
        printstyled(occupied_cores, "\n", color = occupied_cores < jlthreads ? :red : :green)
    else
        printstyled(occupied_cores, occupied_cores < jlthreads ? "(!)" : "", "\n")
    end
    print("└ Thread-Core mapping:")
    # print("   ")
    for (tid, core) in pairs(thread_cpuids)
        print(" $tid => $core,")
        if tid == 5
            print(" ...")
            break
        end
    end
    println("\n")
    if blas
        libblas = BLAS_lib()
        println("BLAS: ", libblas)
        if contains(libblas, "openblas")
            print("└ openblas_get_num_threads: ")
            if color
                printstyled(BLAS.get_num_threads(), "\n", color = _color_openblas_num_threads())
            else
                printstyled(BLAS.get_num_threads(), _color_openblas_num_threads() == :red ? "(!)" : "", "\n")
            end
            println()
            _color_openblas_num_threads(; hints)
        elseif contains(libblas, "mkl")
            print("├ mkl_get_num_threads: ")
            if color
                printstyled(BLAS.get_num_threads(), "\n", color = _color_mkl_num_threads())
            else
                printstyled(BLAS.get_num_threads(), _color_mkl_num_threads() == :red ? "(!)" : "", "\n")
            end
            println("└ mkl_get_dynamic: ", Bool(mkl_get_dynamic()))
            println()
            _color_mkl_num_threads(; hints)
        end
    end
    hints && _general_hints()
    return nothing
end

function _visualize_affinity(; thread_cpuids = getcpuids(), blocksize = 32, color = true)
    print(" ")
    nvcores = Sys.CPU_THREADS
    for (i, puid) in pairs(0:nvcores-1)
        if color
            if puid in thread_cpuids
                printstyled(puid, bold = true, color = :yellow)
            else
                print(puid)
            end
        else
            if puid in thread_cpuids
                printstyled(puid, bold = true)
            else
                print("_")
            end
        end
        !(puid == nvcores - 1) && print(",")
        mod(i, blocksize) == 0 && print("\n ")
    end
    println()
    # legend
    println()
    if color
        printstyled("#", bold = true, color = :yellow)
    else
        printstyled("#", bold = true)
    end
    print(" = Julia thread")
    println("\n")
    return nothing
end
