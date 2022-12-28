"""
Query the number of OpenBLAS threads.
"""
function openblas_nthreads()
    Int(@ccall "libopenblas64_.so".openblas_get_num_threads64_()::Cint)
end

# Sets the thread affinity for the `i`-th OpenBLAS thread. Thread index `i` starts at zero.
function _openblas_setaffinity(i, cpusetsize, cpu_set::Ref{Ccpu_set_t})
    @ccall "libopenblas64_.so".openblas_setaffinity(i::Cint, cpusetsize::Csize_t,
                                                    cpu_set::Ptr{Ccpu_set_t})::Cint
end

# The input `mask` should be either of the following:
#   * a `BitArray` indicating the mask directly
#   * a vector of cpuids (the mask will be constructed automatically)
function _openblas_set_affinity_mask(threadid, mask; juliathread = Threads.threadid())
    cpuset = Ccpu_set_t(mask)
    cpuset_ref = Ref{Ccpu_set_t}(cpuset)
    ret = fetch(@tspawnat juliathread _openblas_setaffinity(threadid - 1, sizeof(cpuset),
                                                            cpuset_ref))
    if ret != 0
        @warn "_openblas_setaffinity call returned a non-zero value (indicating failure)"
    end
    return nothing
end

function _openblas_pinthread(threadid, cpuid; juliathread = Threads.threadid())
    _openblas_set_affinity_mask(threadid, [cpuid]; juliathread)
end

"""
Pin the available OpenBLAS threads to the given CPU IDs. Currently, only explict pinning
is possible.
"""
function openblas_pinthreads(cpuids::AbstractVector{<:Integer};
                             nthreads = openblas_nthreads(),
                             juliathread = Threads.threadid(), kwargs...)
    # TODO: force / first_pin_attempt ?
    _check_cpuids(cpuids)
    limit = min(length(cpuids), nthreads)
    for tid in 1:limit
        _openblas_pinthread(tid, cpuids[tid]; juliathread)
    end
    return nothing
end

# TODO unpin openblas threads

"""
Print the affinity masks of all OpenBLAS threads.

!!! note
    Available as of Julia 1.9.
"""
function openblas_print_affinity_masks end

"""
Returns the ID of the CPU thread on which the `i`-th OpenBLAS thread is currently
running.

!!! note
    Available as of Julia 1.9.
"""
function openblas_getcpuid end

"""
Returns the IDs of the CPU-threads on which the OpenBLAS threads are currently running.

!!! note
    Available as of Julia 1.9.
"""
function openblas_getcpuids end

@static if VERSION >= v"1.9-"
    # `openblas_getaffinity` isn't available in the OpenBLAS versions that older Julia
    # versions ship with. The following functions don't work without it.

    # Get thread affinity for OpenBLAS threads. `thread_idx` starts at 0
    function _openblas_getaffinity(thread_idx, cpusetsize, cpu_set::Ref{Ccpu_set_t})
        @ccall "libopenblas64_.so".openblas_getaffinity(thread_idx::Cint,
                                                        cpusetsize::Csize_t,
                                                        cpu_set::Ptr{Ccpu_set_t})::Cint
    end

    # Query the affinity of an OpenBLAS thread
    function _openblas_get_affinity_mask(threadid; convert = true,
                                         juliathread = Threads.threadid())
        cpuset = Ref{Ccpu_set_t}()
        ret = fetch(@tspawnat juliathread _openblas_getaffinity(threadid - 1,
                                                                sizeof(cpuset), cpuset))
        if ret != 0
            @warn "_openblas_getaffinity call returned a non-zero value (indicating failure)"
        end
        return convert ? Base.convert(BitArray, cpuset[]) : cpuset[]
    end

    function _openblas_affinity_mask_to_string(mask; groupby = :sockets)
        bitstr = reverse(join(bitstring.(reverse(mask.bits))))[1:ncputhreads()]
        if groupby == :numa
            cpuids_per_X = cpuids_per_numa
            nX = nnuma
        else
            cpuids_per_X = cpuids_per_socket
            nX = nsockets
        end
        str = "|"
        for s in 1:nX()
            str = string(str, bitstr[cpuids_per_X()[s] .+ 1], "|")
        end
        return str
    end

    function openblas_print_affinity_masks(; juliathread = Threads.threadid(), kwargs...)
        println("Julia threadid: ", juliathread)
        for i in 1:openblas_nthreads()
            mask = _openblas_get_affinity_mask(i; juliathread, convert = false)
            str = _openblas_affinity_mask_to_string(mask; kwargs...)
            print(rpad("$(i):", 5))
            println(str)
        end
        println()
        return nothing
    end

    function openblas_getcpuid(i; juliathread = Threads.threadid())
        mask = _openblas_get_affinity_mask(i; juliathread)
        if count(mask) == 1 # exactly one bit set
            return findfirst(mask) - 1
        else
            error("The affinity mask of OpenBLAS thread $i includes multiple CPU " *
                  "threads. This likely indicates that this OpenBLAS hasn't been pinned yet.")
        end
    end

    function openblas_getcpuids(; kwargs...)
        nt = openblas_nthreads()
        cpuids = zeros(Int, nt)
        for i in 1:nt
            cpuids[i] = openblas_getcpuid(i; kwargs...)
        end
        return cpuids
    end
end
