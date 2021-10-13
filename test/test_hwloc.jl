using Test
using ThreadPinning

@test_throws Exception pinthreads(:scatter) # Hwloc.jl not loaded

using Hwloc

cpuids_before = getcpuids()
@test isnothing(pinthreads(:scatter))
cpuids_after = getcpuids()

@test cpuids_after != cpuids_before
# check "compact" pinning within each package
npackages = Hwloc.num_packages()
for p in 1:npackages
    ids_within_package = cpuids_after[p:npackages:end]
    @test ids_within_package == minimum(ids_within_package):maximum(ids_within_package)
end