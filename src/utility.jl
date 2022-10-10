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
        if $tid < 1 || $tid > Base.Threads.nthreads()
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

function interweave_uneven(arr1::AbstractVector, arr2::AbstractVector)
    if length(arr1) == length(arr2)
        return interweave(arr1, arr2)
    else
        @views if length(arr1) > length(arr2)
            res_smaller = interweave(arr1[1:length(arr2)], arr2)
            res = vcat(res_smaller, arr1[length(arr2)+1:end])
        else
            res_smaller = interweave(arr1, arr2[1:length(arr1)])
            res = vcat(res_smaller, arr2[length(arr1)+1:end])
        end
        return res
    end
end

hasduplicates(xs::AbstractVector) = length(xs) != length(Set(xs))
