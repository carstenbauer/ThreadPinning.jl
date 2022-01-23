# this file is only loaded on `using Hwloc`,
# i.e. if Hwloc.jl is loaded next to ThreadPinning.jl.

function _hwloc_package_puids()
    packages = Hwloc.collectobjects(:Package)
    package_puids = [getproperty.(Hwloc.collectobjects(:PU, pkg), :logical_index) for pkg in packages]
    return package_puids
end

"""
Implements the "scatter" (or "spread") pinning strategy
based on Hwloc information.

Concretely, it queries the number of packages (sockets)
and their corresponding PU IDs to construct an interweaved
vector of cpuids (compact within each package). It then
calls `pinthreads` with the constructed vector.
"""
function _pin_scatter(nthreads; kwargs...)
    package_puids = _hwloc_package_puids()
    puids = interweave(package_puids...)
    pinthreads(@view puids[1:nthreads])
    return nothing
end

function _visualize_affinity(; thread_cpuids = getcpuids())
    package_puids = _hwloc_package_puids()
    printstyled("| ", bold = true)
    for pkg in package_puids
        for puid in pkg
            if puid in thread_cpuids
                printstyled(puid, bold = true, underline = false, color = :red)
            else
                print(puid)
            end
            !(puid == last(pkg)) && print(",")
        end
        # print(" | ")
        printstyled(" | ", bold = true)
    end
    println()
    # legend
    println()
    printstyled("#", bold = true, underline = false, color = :red)
    print(" = Julia thread, ")
    printstyled("|", bold = true)
    print(" = Package seperator")
    println("\n")
    return nothing
end