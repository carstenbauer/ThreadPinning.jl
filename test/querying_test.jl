using Test
using ThreadPinning

Threads.nthreads() ≥ 2 ||
    error("Can't run tests with single Julia thread! Forgot to set `JULIA_NUM_THREADS`?")

pinthreads(:random)
@test typeof(getcpuid()) == Int
@test typeof(getcpuids()) == Vector{Int}
@test getcpuids() == getcpuid.(1:Threads.nthreads())
@test typeof(nsockets()) == Int
@test ncputhreads() >= 1
@test ncores() >= 1
@test nnuma() >= 1
@test nsockets() >= 1
@test nsmt() >= 1
@test sum(ncputhreads_per_socket()) >= nsockets()
@test sum(ncputhreads_per_numa()) >= nnuma()
@test sum(ncores_per_socket()) >= nsockets()
@test sum(ncores_per_numa()) >= nnuma()
@test typeof(hyperthreading_is_enabled()) == Bool
@test typeof(cpuids_per_socket()) == Vector{Vector{Int}}
@test ishyperthread(0) == false

# TODO improve coverage...
