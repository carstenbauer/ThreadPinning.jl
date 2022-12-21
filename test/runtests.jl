using TestItemRunner

Threads.nthreads() ≥ 4 ||
    error("At least 4 Julia threads necessary. Forgot to set `JULIA_NUM_THREADS`?")

@run_package_tests

@testitem "helper" begin include("helper_test.jl") end
@testitem "preferences" begin include("preferences_test.jl") end

@testitem "querying" begin include("querying_test.jl") end
@testitem "threadinfo" begin include("threadinfo_test.jl") end
@testitem "pinning" begin include("pinning_test.jl") end

@testitem "likwid-pin" begin include("likwid-pin_test.jl") end
# @testitem "OMP" begin include("omp_test.jl") end
