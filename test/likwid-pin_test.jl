using ThreadPinning
using Test

Threads.nthreads() ≥ 4 ||
    error("Need at least 4 Julia threads! Forgot to set `JULIA_NUM_THREADS`?")

lp_expression = "E:N:4:2:4" # E:<domain>:<nthreads>(:<chunk size>:<stride>). 2 threads pinned two first two cpu threads (logical, incl. SMT) and 2 threads pinned to 5th and 6th cpu threads.
lp_scatter_policy = "M:scatter" # scatter threads among all NUMA domains, phyical cores come first

@testset "likwid-pin: explicit" begin
    # physical / OS order
    pinthreads(:random)
    lp_explicit = "0,2,1,3"
    pinthreads(lp_explicit)
    @test getcpuids()[1:4] == [0,2,1,3]

    pinthreads(:random)
    lp_explicit_range = "2-5"
    pinthreads(lp_explicit_range)
    @test getcpuids()[1:4] == 2:5

    pinthreads(:random)
    lp_explicit_ranges = "2-3,5-6"
    pinthreads(lp_explicit_ranges)
    @test getcpuids()[1:4] == vcat(2:3, 5:6)
end

@testset "likwid-pin: domain" begin
    # logical order, physical cores first(!), starts with 0(!)
    pinthreads(:random)
    lp_domain = "S1:0-3" # 4 threads in second socket to first 4 cores
    pinthreads(lp_domain)
    @test getcpuids()[1:4] == cpuids_per_socket[2][1:4]

    # pinthreads(:random)
    # lp_domains = "S0:0-1@S1:0-1" # 2 threads per socket
    # pinthreads(lp_explicit_range)
    # @test getcpuids()[1:4] == 2:5
end
