"""
Calls the function `fn` on all Julia threads
and returns the results obtained on each thread
as a ordered `Vector{Any}`.

Example:
```
julia> Pinning.callonthreads(getcpuid)
8-element Vector{Any}:
  3
  4
  5
  8
  2
 10
  6
  9

julia> pinthreads(1:Threads.nthreads())

julia> Pinning.callonthreads(getcpuid)
8-element Vector{Any}:
 1
 2
 3
 4
 5
 6
 7
 8
```
"""
function callonthreads(fn)
    nt = nthreads()
    res = Vector{Any}(undef, nt)
    @threads :static for tid in 1:nt
        res[tid] = fn()
    end
    return res
end

"""
[1,2,3,4], [5,6,7,8] -> [1,5,2,6,3,7,4,8]
1:4, 5:8, 9:12 == [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
"""
function interweave(arrays::AbstractVector{T}...) where {T}
    # check input args
    narrays = length(arrays)
    narrays > 0 || throw(ArgumentError("No input arguments provided."))
    len = length(first(arrays))
    for a in arrays
        length(a) == len || throw(ArgumentError("Only same length inputs supported."))
    end
    # interweave
    res = zeros(T, len * narrays)
    c = 1
    for i in eachindex(first(arrays))
        for a in arrays
            @inbounds res[c] = a[i]
            c += 1
        end
    end
    return res
end

"""
Check if MKL library \"libmkl_rt.so\" is available in `Libdl.dllist()`
(as is the case when loading MKL.jl or MKL_jll.jl).
"""
mkl_is_loaded() = any(endswith(lib, "libmkl_rt.$(Libdl.dlext)") for lib in Libdl.dllist())

"Try to find \"libmkl_rt.so\" in `Libdl.dllist()`. Returns `nothing` if it can't be found."
function find_mkl()
    for lib in Libdl.dllist()
        if endswith(lib, "libmkl_rt.$(Libdl.dlext)")
            return lib
        end
    end
    return nothing
end

"Call the MKL function `mkl_get_dynamic`."
mkl_get_dynamic() = @ccall find_mkl().mkl_get_dynamic()::Cint

"Call the MKL function `mkl_set_dynamic`."
mkl_set_dynamic(flag::Integer) = @ccall find_mkl().MKL_Set_Dynamic(flag::Cint)::Cvoid

"Potentially throw warnings if the environment is such that thread pinning might not work."
function _check_environment()
    if Threads.nthreads() > 1 && mkl_is_loaded() && mkl_get_dynamic() == 1
        @warn("Found MKL_DYNAMIC == true. Be aware that calling an MKL function can spoil the pinning of Julia threads! Use `ThreadPinning.mkl_set_dynamic(0)` to be safe. See https://discourse.julialang.org/t/julia-thread-affinity-not-persistent-when-calling-mkl-function/74560/3.")
    end
    return nothing
end

"Returns the name of the loaded BLAS library (the first, if multiple are loaded)"
BLAS_lib() = basename(first(BLAS.get_config().loaded_libs).libname)

function _color_mkl_num_threads(; hints = false)
    jlthreads = Threads.nthreads()
    cores = Sys.CPU_THREADS
    cores_per_jlthread = floor(Int, cores / jlthreads)
    blasthreads_per_jlthread = BLAS.get_num_threads()
    if blasthreads_per_jlthread == 1
        if jlthreads < Sys.CPU_THREADS
            hints && @info("blasthreads_per_jlthread == 1 && jlthreads < cores. You should set BLAS.set_num_threads($cores_per_jlthread) or try to increase the number of Julia threads to $cores.")
            return :yellow
        elseif jlthreads == cores
            return :green
        else
            hints && @warn("jlthreads > cores. You should decrease the number of Julia threads to $cores.")
            return :red
        end
    elseif blasthreads_per_jlthread < cores_per_jlthread
        hints && @info("blasthreads_per_jlthread < cores_per_jlthread. You should increase the number of MKL threads, i.e. BLAS.set_num_threads($cores_per_jlthread).")
        return :yellow
    elseif blasthreads_per_jlthread == cores_per_jlthread
        return :green
    else
        hints && @warn("blasthreads_per_jlthread > cores_per_jlthread. You should decrease the number of MKL threads, i.e. BLAS.set_num_threads($cores_per_jlthread).")
        return :red
    end
end

function _color_openblas_num_threads(; hints = false)
    # BLAS uses `blasthreads` many threads in total
    cores = Sys.CPU_THREADS
    blasthreads = BLAS.get_num_threads()
    jlthreads = Threads.nthreads()
    if jlthreads != 1
        if blasthreads == 1
            return :green
        else
            # Not sure about this case...
            if blasthreads < jlthreads
                hints && @warn("jlthreads != 1 && blasthreads < jlthreads. You should set BLAS.set_num_threads(1).")
                return :red
            elseif blasthreads < cores
                hints && @info("jlthreads != 1 && blasthreads < cores. You should either set BLAS.set_num_threads(1) (recommended!) or at least BLAS.set_num_threads($cores).")
                return :yellow
            elseif blasthreads == cores
                hints && @info("For jlthreads != 1 we strongly recommend to set BLAS.set_num_threads(1).")
                return :green
            else
                hints && @warn("jlthreads != 1 && blasthreads > cores. You should set BLAS.set_num_threads(1) (recommended!) or at least BLAS.set_num_threads($cores).")
                return :red
            end
        end
    else
        # single Julia thread
        if blasthreads < cores
            hints && @info("blasthreads < cores. You should increase the number of OpenBLAS threads, i.e. BLAS.set_num_threads($cores).")
            return :yellow
        elseif blasthreads == cores
            return :green
        else
            hints && @warn("blasthreads > cores. You should decrease the number of OpenBLAS threads, i.e. BLAS.set_num_threads($corse).")
            return :red
        end
    end
end

function _general_hints()
    jlthreads = Threads.nthreads()
    cores = Sys.CPU_THREADS
    thread_cpuids = getcpuids()
    if jlthreads > cores
        @warn("jlthreads > cores. You should decrease the number of Julia threads to $cores.")
    elseif jlthreads < cores
        @info("jlthreads < cores. Perhaps increase number of Julia threads to $cores?")
    end
    if length(unique(thread_cpuids)) < jlthreads
        @warn("Overlap: Some Julia threads are running on the same core!")
    end
    return nothing
end

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