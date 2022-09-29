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

# global "constant"
const SYSINFO = Ref{SysInfo}(SysInfo())
