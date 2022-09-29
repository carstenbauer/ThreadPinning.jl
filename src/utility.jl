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

function update_sysinfo!(lscpustr = nothing; verbose = false)
    sysinfo = gather_sysinfo_lscpu(lscpustr; verbose)
    if isnothing(sysinfo)
        @warn("Couldn't gather system information via `lscpu` (might not be available?). Some features won't work optimally, others might not work at all.")
        SYSINFO[] = SysInfo() # default fallback
    else
        SYSINFO[] = sysinfo
    end
    return nothing
end

function read_lscpu(lscpustr = nothing)
    local table
    if isnothing(lscpustr)
        try
            buf = IOBuffer(read(`lscpu --all --extended`, String))
            table = readdlm(buf, String)
        catch
            return nothing
        end
    else
        # for debugging purposes
        table = readdlm(IOBuffer(lscpustr), String)
    end
end

function gather_sysinfo_lscpu(lscpustr = nothing; verbose = false)
    table = read_lscpu(lscpustr)
    colid_socket = @views findfirst(isequal("SOCKET"), table[1, :])
    colid_numa = @views findfirst(isequal("NODE"), table[1, :])
    colid_core = @views findfirst(isequal("CORE"), table[1, :])
    colid_cpu = @views findfirst(isequal("CPU"), table[1, :])
    colid_online = @views findfirst(isequal("ONLINE"), table[1, :])
    online_cpu_tblidcs = @views findall(isequal("yes"), table[:, colid_online])
    verbose && @show online_cpu_tblidcs
    if length(online_cpu_tblidcs) != Sys.CPU_THREADS
        @warn("Could read `lscpu --all --extended` but number of online CPUs ($(length(online_cpu_tblidcs))) doesn't match Sys.CPU_THREADS ($(Sys.CPU_THREADS)).")
    end
    cpuids = @views parse.(Int, table[online_cpu_tblidcs, colid_cpu])
    verbose && @show cpuids
    # count number of sockets
    nsockets = if isnothing(colid_socket)
        1
    else
        @views length(unique(table[online_cpu_tblidcs, colid_socket]))
    end
    verbose && @show nsockets
    # count number of numa nodes
    nnuma = if isnothing(colid_numa)
        1
    else
        @views length(unique(table[online_cpu_tblidcs, colid_numa]))
    end
    verbose && @show nnuma
    # cpuids per socket / numa
    cpuids_sockets = [Int[] for _ in 1:nsockets]
    cpuids_numa = [Int[] for _ in 1:nnuma]
    prev_numa = 0
    prev_socket = 0
    numaidcs = Dict{Int, Int}(0 => 1)
    socketidcs = Dict{Int, Int}(0 => 1)
    for i in online_cpu_tblidcs
        cpuid = parse(Int, table[i, colid_cpu])
        numa = isnothing(colid_numa) ? 0 : parse(Int, table[i, colid_numa])
        socket = isnothing(colid_socket) ? 0 : parse(Int, table[i, colid_socket])
        if numa != prev_numa
            if !haskey(numaidcs, numa)
                numaidcs[numa] = maximum(values(numaidcs)) + 1
            end
            prev_numa = numa
        end
        if socket != prev_socket
            if !haskey(socketidcs, socket)
                socketidcs[socket] = maximum(values(socketidcs)) + 1
            end
            prev_socket = socket
        end
        numaidx = numaidcs[numa]
        socketidx = socketidcs[socket]
        push!(cpuids_sockets[socketidx], cpuid)
        push!(cpuids_numa[numaidx], cpuid)
    end
    # if a coreid is seen for a second time
    # the corresponding cpuid is identified
    # as a hypterthread
    ishyperthread = fill(false, length(online_cpu_tblidcs))
    seen_coreids = Set{Int}()
    for i in online_cpu_tblidcs
        cpuid = parse(Int, table[i, colid_cpu])
        coreid = parse(Int, table[i, colid_core])
        if coreid in seen_coreids
            # mark as hyperthread
            cpuidx = findfirst(isequal(cpuid), cpuids)
            ishyperthread[cpuidx] = true
        end
        push!(seen_coreids, coreid)
    end
    # hyperthreading?
    hyperthreading = any(ishyperthread)
    verbose && @show hyperthreading
    return SysInfo(nsockets, nnuma, hyperthreading, cpuids, cpuids_sockets, cpuids_numa,
                   ishyperthread)
end

hasduplicates(xs::AbstractVector) = length(xs) != length(Set(xs))

function lscpu()
    run(`lscpu --all --extended`)
    return nothing
end
