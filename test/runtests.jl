using SafeTestsets

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

@time begin
    @time @safetestset "Helper" begin include("helper_test.jl") end
    @time @safetestset "System Info" begin include("sysinfo_test.jl") end
    @time @safetestset "Pinning" begin include("pinning_test.jl") end
    @time @safetestset "Querying" begin include("querying_test.jl") end
    @time @safetestset "threadinfo" begin include("threadinfo_test.jl") end
    @time @safetestset "OMP" begin include("omp_test.jl") end
end
