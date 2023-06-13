module SLURM

import ..ThreadPinning: ncputhreads

"""
Returns `true` if the current Julia session is (most likely) running in an
active SLURM job.
"""
isslurmjob() = haskey(ENV, "SLURM_JOBID")

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
        return parse(Int64, slurm_cpus_on_node) == ncputhreads
    end
    return true
end

end
