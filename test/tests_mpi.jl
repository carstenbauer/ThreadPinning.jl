using ThreadPinning
using MPI

testdir = joinpath(@__DIR__, "mpi/")
# excludefiles = []
excludefiles = ["mpitests_pinning.jl"]
istest(f) = endswith(f, ".jl") && startswith(f, "mpitests_") && !in(f, excludefiles)
testfiles = sort(filter(istest, readdir(testdir)))

np = min(ncputhreads(), 4)
nt = min(floor(Int, ncputhreads() / np), nnuma())
@info("MPI Tests", np, nt)

# Pure MPI (i.e. single Julia thread per MPI rank)
@testset "$f" for f in testfiles
    function cmd(n = np)
        `$(mpiexec()) -n $np $(Base.julia_cmd()) --startup-file=no $(joinpath(testdir, f))`
    end
    withenv("JULIA_NUM_THREADS" => 1) do
        run(cmd())
        @test true
    end
end

# Hybrid MPI (i.e. nt Julia threads per MPI rank)
@testset "$f (MPI+Threads)" for f in testfiles
    function cmd(n = np)
        `$(mpiexec()) -n $np $(Base.julia_cmd()) --startup-file=no $(joinpath(testdir, f))`
    end
    withenv("JULIA_NUM_THREADS" => nt) do
        run(cmd())
        @test true
    end
end
