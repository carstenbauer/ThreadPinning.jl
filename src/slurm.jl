module SLURM

import ..ThreadPinning: ncputhreads

"""
Returns `true` if the current Julia session is (most likely) running in an
active SLURM job.
"""
isslurmjob() = get(ENV, "SLURM_JOBID", "") != ""

"""
Returns `false` if the Julia session is (most likely) running in a SLURM allocation
that doesn't cover the entire node. Return `true` otherwise (including if we're not in a
SLURM allocation at all).
"""
function hasfullnode()
    if !isslurmjob()
        return true
    end
    slurm_cpus_on_node = get(ENV, "SLURM_CPUS_ON_NODE", nothing)
    if !isnothing(slurm_cpus_on_node)
        return parse(Int64, slurm_cpus_on_node) == ncputhreads()
    end
    return true
end

function get_cpu_mask_str()
    slurm_str = get(ENV, "SLURM_CPU_BIND", nothing)
    if isnothing(slurm_str)
        slurm_str = get(ENV, "SLURM_CPU_BIND_LIST", nothing)
    end
    mask_str = nothing
    if !isnothing(slurm_str)
        sp = split(slurm_str, "0x")
        if length(sp) == 2
            mask_str = string("0x", sp[2])
            return mask_str
        end
    end
    return nothing
end

function get_cpu_mask(mask_str = get_cpu_mask_str())
    if isnothing(mask_str)
        return nothing
    end
    mask = parse(Int, mask_str)
    return digits(mask; base=2, pad=ncputhreads())
end

function ncpus_per_task()::Int
    n = get(ENV, "SLURM_CPUS_PER_TASK", nothing)
    if !isnothing(n)
        return parse(Int, n)
    end
    slurm_mask = get_cpu_mask()
    if !isnothing(slurm_mask)
        return count(isequal(1), slurm_mask)
    end
    return 0
end

end
