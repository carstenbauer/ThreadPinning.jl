using ThreadPinning
using MPI

const testdir = joinpath(@__DIR__, "mpi/")

const maxnprocs = min(ncputhreads(), 4)

for f in filter(startswith("mpi_"), readdir(testdir))
    cmd(n=nprocs) = `$(mpiexec()) -n $n $(Base.julia_cmd()) --startup-file=no $(joinpath(testdir, f))`
    run(cmd(maxnprocs))
end
