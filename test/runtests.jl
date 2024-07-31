using TestItemRunner

Threads.nthreads() ≥ 4 ||
    error("At least 4 Julia threads necessary. Forgot to set `JULIA_NUM_THREADS`?")

quiet_testing = parse(Bool, get(ENV, "TP_TEST_QUIET", "true"))
@show quiet_testing

@run_package_tests

# run on all OSs
@testitem "threadinfo" begin
    include("tests_threadinfo.jl")
end
@testitem "slurm" begin
    include("tests_slurm.jl")
end

# run only on certain OSs
if Sys.islinux()
    @testitem "querying" begin
        include("tests_querying.jl")
    end
    @testitem "pinning" begin
        include("tests_pinning.jl")
    end
elseif Sys.isapple() || Sys.iswindows()
    @testitem "nonlinux" begin
        include("tests_nonlinux.jl")
    end
end

# @testitem "likwid-pin" begin include("tests_likwid-pin.jl") end
# @testitem "openblas" begin include("tests_openblas.jl") end
# @testitem "core2core latency" begin include("tests_latency.jl") end
# @testitem "intel mkl" begin include("tests_mkl.jl") end
