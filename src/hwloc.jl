# this file is only loaded on `using Hwloc`,
# i.e. if Hwloc.jl is loaded next to ThreadPinning.jl.

"""
Implements the "scatter" (or "spread") pinning strategy
based on Hwloc information.

Concretely, it queries the number of packages (sockets)
and their corresponding PU IDs to construct an interweaved
vector of cpuids (compact within each package). It then
calls `pinthreads` with the constructed vector.
"""
function _pin_scatter(nthreads; kwargs...)
    packages = Hwloc.collectobjects(:Package)
    package_puids = [getproperty.(Hwloc.collectobjects(:PU, pkg), :logical_index) for pkg in packages]
    puids = interweave(package_puids...)
    pinthreads(@view puids[1:nthreads])
    return nothing
end