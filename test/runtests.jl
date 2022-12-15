using TestItemRunner

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

@run_package_tests

@testitem "Helper" begin include("helper_test.jl") end
@testitem "System Info" begin include("sysinfo_test.jl") end
@testitem "Pinning" begin include("pinning_test.jl") end
@testitem "Querying" begin include("querying_test.jl") end
@testitem "threadinfo" begin include("threadinfo_test.jl") end
@testitem "OMP" begin include("omp_test.jl") end
@testitem "Preferences" begin include("preferences_test.jl") end
@testitem "likwid-pin" begin include("likwid-pin_test.jl") end
