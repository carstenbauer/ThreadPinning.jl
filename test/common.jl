using Logging
quiet_testing = parse(Bool, get(ENV, "TP_TEST_QUIET", "true"))
if quiet_testing
    ThreadPinning.DEFAULT_IO[] = Base.BufferStream()
    # global_logger(Logging.NullLogger())
end
const IS_GITHUB_CI = haskey(ENV, "GITHUB_ACTIONS")
@show IS_GITHUB_CI
