using TestItemRunner

Threads.nthreads() ≥ 4 ||
    error("At least 4 Julia threads necessary. Forgot to set `JULIA_NUM_THREADS`?")

@static if VERSION >= v"1.9-"
    @show Base.Threads.nthreads(:default)
    @show Base.Threads.nthreads(:interactive)
end

@run_package_tests

@testitem "utility" begin include("utility_test.jl") end
@testitem "preferences" begin include("preferences_test.jl") end

@testitem "querying" begin include("querying_test.jl") end
@testitem "threadinfo" begin include("threadinfo_test.jl") end
@testitem "pinning" begin include("pinning_test.jl") end

@testitem "likwid-pin" begin include("likwid-pin_test.jl") end
@testitem "openblas" begin include("openblas_test.jl") end
@testitem "core2core latency" begin include("latency_test.jl") end
@testitem "intel mkl" begin include("mkl_test.jl") end
