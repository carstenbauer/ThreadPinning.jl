module Utility

"""
# Examples
```julia
interweave([1,2,3,4], [5,6,7,8]) == [1,5,2,6,3,7,4,8]
```
```julia
interweave(1:4, 5:8, 9:12) == [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
```
"""
function interweave(arrays::AbstractVector...)
    # check input args
    narrays = length(arrays)
    narrays > 0 || throw(ArgumentError("No input arguments provided."))
    len = length(first(arrays))
    for a in arrays
        length(a) == len || throw(ArgumentError("Only same length inputs supported."))
    end
    # interweave
    res = zeros(eltype(first(arrays)), len * narrays)
    c = 1
    for i in eachindex(first(arrays))
        for a in arrays
            @inbounds res[c] = a[i]
            c += 1
        end
    end
    return res
end

function interweave_binary(arr1::AbstractVector, arr2::AbstractVector)
    if length(arr1) == length(arr2)
        return interweave(arr1, arr2)
    else
        @views if length(arr1) > length(arr2)
            res_smaller = interweave(arr1[1:length(arr2)], arr2)
            res = vcat(res_smaller, arr1[(length(arr2) + 1):end])
        else
            res_smaller = interweave(arr1, arr2[1:length(arr1)])
            res = vcat(res_smaller, arr2[(length(arr1) + 1):end])
        end
        return res
    end
end

hasduplicates(xs) = length(xs) != length(Set(xs))

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
