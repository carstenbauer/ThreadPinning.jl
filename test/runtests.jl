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

# run only on Linux
@testitem "querying" begin
    Sys.islinux() && include("tests_querying.jl")
end
@testitem "pinning" begin
    Sys.islinux() && include("tests_pinning.jl")
end
@testitem "likwid-pin" begin
    Sys.islinux() && include("tests_likwid-pin.jl")
end
@testitem "openblas" begin
    Sys.islinux() && include("tests_openblas.jl")
end

# run only on macOS/Windows
@testitem "nonlinux" begin
    (Sys.isapple() || Sys.iswindows()) && include("tests_nonlinux.jl")
end

# TODO: pinthreads_mpi

# @testitem "intel mkl" begin include("tests_mkl.jl") end
