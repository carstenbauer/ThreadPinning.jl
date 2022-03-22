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
            throw(
                AssertionError(
                    "@tspawnat thread assignment ($($tid)) must be between 1 and Threads.nthreads() (1:$(Threads.nthreads()))",
                ),
            )
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

function gather_sysinfo_lscpu()
    local table
    try
        table = readdlm(IOBuffer(read(`lscpu --all --extended`, String)))
    catch
        return false
    end
    if size(table, 1) != Sys.CPU_THREADS + 1
        @warn(
            "Could read `lscpu --all --extended` but number of cpuids doesn't match Sys.CPU_THREADS. Falling back to defaults."
        )
    end
    # hyperthreading?
    HYPERTHREADING[] = hasduplicates(@view(table[2:end, 4]))
    # count number of sockets
    NSOCKETS[] = length(unique(@view(table[2:end, 3])))
    # count number of numa nodes
    NNUMA[] = length(unique(@view(table[2:end, 2])))
    # cpuids per socket / numa
    CPUIDS[] = [Int[] for _ in 1:nsockets()]
    CPUIDS_NUMA[] = [Int[] for _ in 1:nnuma()]
    for i in 2:size(table, 1)
        cpuid = table[i, 1]
        numa = table[i, 2]
        socket = table[i, 3]
        push!(CPUIDS[][socket + 1], cpuid)
        push!(CPUIDS_NUMA[][numa + 1], cpuid)
    end
    # if a coreid is seen for a second time
    # the corresponding cpuid is identified
    # as a hypterthread
    ISHYPERTHREAD[] = fill(false, Sys.CPU_THREADS)
    seen_coreids = Set{Int}()
    for i in 2:size(table, 1)
        cpuid = table[i, 1]
        coreid = table[i, 4]
        if coreid in seen_coreids
            # mark as hyperthread
            ISHYPERTHREAD[][cpuid + 1] = true
        end
        push!(seen_coreids, coreid)
    end
    return true
end

hasduplicates(xs::AbstractVector) = length(xs) != length(Set(xs))

function lscpu()
    run(`lscpu --all --extended`)
    return nothing
end