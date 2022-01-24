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

function _visualize_affinity(; thread_cpuids = getcpuids(), blocksize = 32, color = true, ht = hyperthreading_is_enabled())
    package_puids = _hwloc_package_puids()
    nvcores = Hwloc.num_virtual_cores()
    printstyled("| ", bold = true)
    for (i, pkg) in pairs(package_puids)
        for (k, puid) in pairs(pkg)
            if color
                if puid in thread_cpuids
                    printstyled(puid, bold = true, color = (ht && isodd(puid)) ? :magenta : :red)
                else
                    printstyled(puid, color = (ht && isodd(puid)) ? :black : :default)
                end
            else
                if puid in thread_cpuids
                    printstyled(puid, bold = true)
                else
                    print("_")
                end
            end
            if !(puid == last(pkg))
                print(",")
                mod(k, blocksize) == 0 && print("\n  ")
            end
        end
        # print(" | ")
        if nvcores > 20
            printstyled(" |", bold = true)
            if !(i == length(package_puids))
                println()
                printstyled("| ", bold = true)
            end
        else
            printstyled(" | ", bold = true)
        end
    end
    println()
    # legend
    println()
    if color
        printstyled("#", bold = true, color = :red)
    else
        printstyled("#", bold = true)
    end
    print(" = Julia thread, ")
    printstyled("|", bold = true)
    print(" = Package seperator")
    println("\n")
    return nothing
end

hyperthreading_is_enabled() = !(Hwloc.num_virtual_cores() == Hwloc.num_physical_cores())