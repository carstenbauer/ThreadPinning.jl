include("common.jl")
using ThreadPinning
using Test

@test length(methods(pinthreads_mpi)) == 0 # extension not loaded yet
using MPI
@test length(methods(pinthreads_mpi)) > 0 # extension loaded

# TODO....
