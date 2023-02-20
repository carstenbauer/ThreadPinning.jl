#!/usr/bin/env sh
#=
ml lang JuliaHPC
me=`basename "$0"`
mpiexecjl -n 2 --oversubscribe --project julia -t 10 $me > $me.out
exit
# =#
using MPI
using ThreadPinning

MPI.Init()

nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)

pinthreads_mpi(:sockets, rank, nranks)

sleep(0.3 * rank)
println("Rank $rank:")
println("\tHost: ", gethostname())
println("\tCPUs: ", getcpuids())

MPI.Finalize()
