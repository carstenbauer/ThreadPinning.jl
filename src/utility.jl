module Utility

import ThreadPinning
import ThreadPinningCore
import SysInfo
using LinearAlgebra: BLAS

"Turn the vector of CPU IDs into an affinity mask (a vector of ones and zeros)."
function cpuids2affinitymask(cpuids::AbstractVector{<:Integer})
    mask = ThreadPinningCore.emptymask()
    for (i, c) in pairs(ThreadPinning.cpuids())
        if c in cpuids
            mask[i] = one(eltype(mask))
        end
    end
    return mask
end

"Turn the affinity mask (a vector of ones and zeros) into a vector of CPU IDs."
function affinitymask2cpuids(mask::Union{AbstractVector{<:Integer}, BitVector}; kwargs...)
    cpuids_all = ThreadPinning.cpuids(; kwargs...)
    return [cpuids_all[i] for (i, v) in enumerate(mask) if v == 1]
end

"Returns the name of the loaded BLAS library (the first, if multiple are loaded)."
BLAS_lib() = basename(first(BLAS.get_config().loaded_libs).libname)

"Number of BLAS threads."
nblasthreads() = BLAS.get_num_threads()

"Run a Cmd object, returning the stdout & stderr contents plus the exit code"
function _execute(cmd::Cmd)
    out = Pipe()
    err = Pipe()

    process = run(pipeline(ignorestatus(cmd); stdout = out, stderr = err))
    close(out.in)
    close(err.in)

    out = (stdout = String(read(out)), stderr = String(read(err)),
        exitcode = process.exitcode)
    return out
end

"Returns a (most likely) unique id for the calling task."
taskid() = objectid(current_task())

end # module
