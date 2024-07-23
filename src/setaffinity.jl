"""
$(TYPEDSIGNATURES)Set the affinity of the calling Julia thread to the given CPU-threads.

*Example:*
* `setaffinity(socket(1))` # set the affinity to the first socket
* `setaffinity(numa(2))` # set the affinity to the second NUMA domain
* `setaffinity(socket(1, 1:3))` # set the affinity to the first three cores in the first NUMA domain
* `setaffinity([1,3,5])` # set the affinity to the CPU-threads with the IDs 1, 3, and 5.
"""
function setaffinity(cpuids::AbstractVector{<:Integer})
    _check_cpuids(cpuids)
    mask = cpuids2affinitymask(cpuids)
    uv_thread_setaffinity(mask)
    return
end
"""
$(TYPEDSIGNATURES)Set the affinity of a specific Julia thread to the given CPU-threads.
"""
function setaffinity(threadid::Integer, cpuids::AbstractVector{<:Integer}; kwargs...)
    fetch(@spawnat threadid setaffinity(cpuids; kwargs...))
    return
end

function cpuids2affinitymask(cpuids::AbstractVector{<:Integer})
    masksize = uv_cpumask_size()
    cpumask = zeros(Cchar, masksize)
    for (i,c) in pairs(cpuids_all())
        if c in cpuids
            cpumask[i] = one(Cchar)
        end
    end
    return cpumask
end
