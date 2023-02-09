#!/usr/bin/env sh
#SBATCH -N 1
#SBATCH -o sl_mpi_hybrid_explicit%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
srun -n 4 julia --project -t 10 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#
using MPI
using ThreadPinning

MPI.Init()

nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)

pinthreads_mpi(:sockets, rank, nranks)

sleep(0.3 * rank)
println("Rank $rank: ", getcpuids())

MPI.Finalize()
