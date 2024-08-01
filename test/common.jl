using Logging
quiet_testing = parse(Bool, get(ENV, "TP_TEST_QUIET", "true"))
if quiet_testing
    ThreadPinning.DEFAULT_IO[] = Base.BufferStream()
    # global_logger(Logging.NullLogger())
end
const IS_GITHUB_CI = haskey(ENV, "GITHUB_ACTIONS")
@show IS_GITHUB_CI

# get two valid cpu ids on the current system
function get_two_cpuids()
    all_cpuids = ThreadPinning.cpuids()
    cpuid1 = getcpuid()
    cpuid1_idx = findfirst(==(cpuid1), all_cpuids)
    deleteat!(all_cpuids, cpuid1_idx)
    # find another cpuid that is close to the one before
    _, idx = findmin(x -> abs(x - cpuid1), all_cpuids)
    cpuid2 = all_cpuids[idx]
    return cpuid1, cpuid2
end
