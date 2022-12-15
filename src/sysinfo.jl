# system information
Base.@kwdef struct SysInfo
    ncputhreads::Int = Sys.CPU_THREADS
    ncores::Int = Sys.CPU_THREADS
    nnuma::Int = 1
    nsockets::Int = 1
    hyperthreading::Bool = false
    cpuids::Vector{Int} = collect(0:(Sys.CPU_THREADS - 1)) # lscpu ordering
    cpuids_sockets::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    cpuids_numa::Vector{Vector{Int}} = [collect(0:(Sys.CPU_THREADS - 1))]
    cpuids_core::Vector{Vector{Int}} = [[i] for i in 0:(Sys.CPU_THREADS - 1)]
    ishyperthread::Vector{Bool} = fill(false, Sys.CPU_THREADS)
    # Columns of the sysinfo matrix (in that order):
    #   * ID (logical, i.e. starts at 1)
    #   * CPU IDs (as in lscpu, i.e. starts at 0)
    #   * CORE (logical, i.e. starts at 1)
    #   * NUMA (logical, i.e. starts at 1)
    #   * SOCKET (logical, i.e. starts at 1)
    #   * SMT (logical, i.e. starts at 1): order of SMT threads ("hyperthreads") within their respective core
    matrix::Matrix{Int} = hcat(1:(Sys.CPU_THREADS), cpuids, 1:(Sys.CPU_THREADS),
                               ones(Sys.CPU_THREADS),
                               ones(Sys.CPU_THREADS), ones(Sys.CPU_THREADS))
end

# helper indices for indexing into the sysinfo matrix
const IID = 1
const ICPUID = 2
const ICORE = 3
const INUMA = 4
const ISOCKET = 5
const ISMT = 6
function getsortedby(getidx, byidx; matrix = sysinfo().matrix, kwargs...)
    @views sortslices(matrix; dims = 1, by = x -> x[byidx], kwargs...)[:, getidx]
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
    @assert issorted(cols.cpuid)
    @assert length(Set(cols.cpuid)) == length(cols.cpuid) # no duplicates
    # count number of cputhreads
    ncputhreads = length(cols.cpuid)
    verbose && @show ncputhreads
    # count number of cores
    ncores = length(unique(cols.core))
    verbose && @show ncores
    # count number of sockets
    nsockets = length(unique(cols.socket))
    verbose && @show nsockets
    # count number of numa nodes
    nnuma = length(unique(cols.numa))
    verbose && @show nnuma
    # count number of SMT threads per core (assuming its the same for all cores!)
    nsmt = count(cols.core .== 1)

    # cpuids per socket / numa
    cpuids_sockets = [Int[] for _ in 1:nsockets]
    cpuids_numa = [Int[] for _ in 1:nnuma]
    cpuids_core = [Int[] for _ in 1:ncores]
    prev_numa = 0
    prev_socket = 0
    prev_core = 0
    numaidcs = Dict{Int, Int}(0 => 1)
    socketidcs = Dict{Int, Int}(0 => 1)
    coreidcs = Dict{Int, Int}(0 => 1)
    @inbounds for i in cols.idcs
        cpuid = cols.cpuid[i]
        numa = cols.numa[i]
        socket = cols.socket[i]
        core = cols.core[i]
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
        if core != prev_core
            if !haskey(coreidcs, core)
                coreidcs[core] = maximum(values(coreidcs)) + 1
            end
            prev_core = core
        end
        numaidx = numaidcs[numa]
        socketidx = socketidcs[socket]
        coreidx = coreidcs[core]
        push!(cpuids_sockets[socketidx], cpuid)
        push!(cpuids_numa[numaidx], cpuid)
        push!(cpuids_core[coreidx], cpuid)
    end
    # if a coreid is seen for a second time
    # the corresponding cpuid is identified
    # as a hypterthread
    # TODO: Simplify based on cpuids_core
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

    # sysinfo matrix
    matrix = hcat(1:ncputhreads, cols.cpuid, cols.core .+ 1, cols.numa .+ 1,
                  cols.socket .+ 1,
                  zeros(Int64, ncputhreads))
    matrix[getsortedby(IID, ICORE; matrix), ISMT] .= mod1.(1:ncputhreads, nsmt)

    #TODO ensure specific default sorting of sysinfo matrix

    return SysInfo(; ncputhreads, ncores, nnuma, nsockets, hyperthreading, cpuids,
                   cpuids_sockets,
                   cpuids_numa, cpuids_core, ishyperthread, matrix)
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
const LSCPU_STRING = @static if Sys.islinux()
    lscpu_string()
else
    "nolinux"
end
