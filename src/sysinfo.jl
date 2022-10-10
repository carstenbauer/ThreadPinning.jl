# system information
Base.@kwdef struct SysInfo
    nsockets::Int = 1
    nnuma::Int = 1
    hyperthreading::Bool = false
    cpuids::Vector{Int} = collect(0:(Sys.CPU_THREADS - 1))
    cpuids_sockets::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    cpuids_numa::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    ishyperthread::Vector{Bool} = fill(false, Sys.CPU_THREADS)
end
function Base.show(io::IO, sysinfo::SysInfo)
    return print(io, "SysInfo()")
end
function Base.show(io::IO, mime::MIME{Symbol("text/plain")}, sysinfo::SysInfo)
    summary(io, sysinfo)
    println(io)
    fnames = fieldnames(SysInfo)
    for fname in fnames[1:(end - 1)]
        println(io, "├ $fname: ", getfield(sysinfo, fname))
    end
    print(io, "└ $(fnames[end]): ", getfield(sysinfo, fnames[end]))
    return nothing
end

# lscpu parsing
function update_sysinfo!(; fromscratch = false, lscpustr = nothing, verbose = false,
                         clear = false)
    if clear
        SYSINFO[] = SysInfo()
    else
        local sysinfo
        try
            if !isnothing(lscpustr)
                # explicit lscpu string given
                sysinfo = lscpu2sysinfo(lscpustr; verbose)
            else
                if !fromscratch
                    # use precompiled lscpu string
                    sysinfo = lscpu2sysinfo(LSCPU_STRING; verbose)
                else
                    # from scratch: query lscpu again
                    sysinfo = lscpu2sysinfo(lscpu_string(); verbose)
                end
            end
        catch err
            throw(ArgumentError("Couldn't parse the given lscpu string:\n\n $lscpustr \n\n"))
        end
        SYSINFO[] = sysinfo
    end
    return nothing
end

function lscpu2sysinfo(lscpustr = nothing; verbose = false)
    table = _lscpu2table(lscpustr)
    cols = _lscpu_table_to_columns(table; verbose)
    verbose && @show cols
    sysinfo = _create_sysinfo_obj(cols; verbose)
    return sysinfo
end

_lscpu2table(lscpustr = nothing)::Union{Nothing, Matrix{String}} = readdlm(IOBuffer(lscpustr),
                                                                           String)

function _lscpu_table_to_columns(table;
                                 verbose = false)::NamedTuple{
                                                              (:idcs, :cpuid, :socket,
                                                               :numa, :core),
                                                              NTuple{5, Vector{Int}}}
    colid_cpu = @views findfirst(isequal("CPU"), table[1, :])
    colid_socket = @views findfirst(isequal("SOCKET"), table[1, :])
    colid_numa = @views findfirst(isequal("NODE"), table[1, :])
    colid_core = @views findfirst(isequal("CORE"), table[1, :])
    colid_online = @views findfirst(isequal("ONLINE"), table[1, :])

    # only consider online cpus
    online_cpu_tblidcs = @views findall(isequal("yes"), table[:, colid_online])
    verbose && @show online_cpu_tblidcs
    if length(online_cpu_tblidcs) != Sys.CPU_THREADS
        @warn("Number of online CPUs ($(length(online_cpu_tblidcs))) doesn't match Sys.CPU_THREADS ($(Sys.CPU_THREADS)).")
    end

    col_cpuid = @views parse.(Int, table[online_cpu_tblidcs, colid_cpu])
    col_socket = if isnothing(colid_socket)
        fill(zero(Int), length(online_cpu_tblidcs))
    else
        @views parse.(Int, table[online_cpu_tblidcs, colid_socket])
    end
    col_numa = if isnothing(colid_numa)
        fill(zero(Int), length(online_cpu_tblidcs))
    else
        @views parse.(Int, table[online_cpu_tblidcs, colid_numa])
    end
    col_core = @views parse.(Int, table[online_cpu_tblidcs, colid_core])
    idcs = 1:length(online_cpu_tblidcs)

    @assert length(idcs) == length(col_cpuid) == length(col_socket) == length(col_numa) ==
            length(col_core)
    return (idcs = idcs, cpuid = col_cpuid, socket = col_socket, numa = col_numa,
            core = col_core)
end

function _create_sysinfo_obj(cols; verbose = false)
    cpuids = cols.cpuid
    verbose && @show cpuids
    # count number of sockets
    nsockets = length(unique(cols.socket))
    verbose && @show nsockets
    # count number of numa nodes
    nnuma = length(unique(cols.numa))
    verbose && @show nnuma
    # cpuids per socket / numa
    cpuids_sockets = [Int[] for _ in 1:nsockets]
    cpuids_numa = [Int[] for _ in 1:nnuma]
    prev_numa = 0
    prev_socket = 0
    numaidcs = Dict{Int, Int}(0 => 1)
    socketidcs = Dict{Int, Int}(0 => 1)
    @inbounds for i in cols.idcs
        cpuid = cols.cpuid[i]
        numa = cols.numa[i]
        socket = cols.socket[i]
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
    ishyperthread = fill(false, length(cols.idcs))
    seen_coreids = Set{Int}()
    @inbounds for i in cols.idcs
        cpuid = cols.cpuid[i]
        coreid = cols.core[i]
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

function lscpu()
    run(`lscpu --all --extended`)
    return nothing
end

function lscpu_string()
    try
        return read(`lscpu --all --extended`, String)
    catch err
        error("Couldn't gather system information via `lscpu` (might not be available?).")
    end
end

# global "constant"
const SYSINFO = Ref{SysInfo}(SysInfo())
const LSCPU_STRING = lscpu_string()
