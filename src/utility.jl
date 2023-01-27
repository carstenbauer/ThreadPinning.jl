"""
    @tspawnat tid -> task
Mimics `Threads.@spawn`, but assigns the task to thread `tid` (with `sticky = true`).

Note for Julia >= 1.9: Threads in the `:interactive` thread pool come after those in
`:default`. Hence, use a thread id `tid > nthreads(:default)` to spawn computations on
"interactive" threads.

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
    @static if VERSION < v"1.9-"
        nt = :(Threads.nthreads())
    else
        nt = :(Threads.maxthreadid())
    end
    quote
        if $tid < 1 || $tid > $nt
            throw(ArgumentError("Invalid thread id ($($tid)). Must be between in " *
                                "1:(total number of threads), i.e. $(1:$nt)."))
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
$(TYPEDSIGNATURES)
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
function BLAS_lib()
    @static if VERSION < v"1.7-"
        string(BLAS.vendor())
    else
        basename(first(BLAS.get_config().loaded_libs).libname)
    end
end

"Number of BLAS threads."
nblasthreads() = BLAS.get_num_threads()
