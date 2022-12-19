using Test
using ThreadPinning
using ThreadPinning: ICORE, ICPUID

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

@testset "cpuids_per_*" begin
    for compact in (false, true)
        cpuids = cpuids_per_node(; compact)
        @test typeof(cpuids) == Vector{Int}
        @test length(cpuids) == ncputhreads()
        if hyperthreading_is_enabled()
            if !compact
                @test issorted(cpuids, by = ishyperthread) # physical cores first
                @test !issorted(ThreadPinning.cpuid2core.(cpuids), by = ishyperthread)
            else
                @test !issorted(cpuids, by = ishyperthread)
                @test issorted(ThreadPinning.cpuid2core.(cpuids), by = ishyperthread)
            end
        end
    end
    for f in (cpuids_per_socket, cpuids_per_numa)
        for compact in (false, true)
            cpuids = f(; compact)
            @test typeof(cpuids) == Vector{Vector{Int}}
            @test sum(length, cpuids) == ncputhreads()
            if hyperthreading_is_enabled()
                if !compact
                    for i in eachindex(cpuids)
                        @test issorted(cpuids[i], by = ishyperthread) # physical cores first
                    end
                else
                    for i in eachindex(cpuids)
                        @test !issorted(cpuids[i], by = ishyperthread)
                    end
                end
            end
        end
    end
    let cpuids = cpuids_per_core()
        for cpuids_core in cpuids
            # all threads expect first should be "hyperthreads"
            @test !ishyperthread(first(cpuids_core))
            @test @views all(ishyperthread.(cpuids_core[2:end]))
        end
    end
end

@testset "cpuid2core" begin
    M = sysinfo().matrix
    @test @views ThreadPinning.cpuid2core.(M[:, ICPUID]) == M[:, ICORE]
end
# TODO improve coverage...
