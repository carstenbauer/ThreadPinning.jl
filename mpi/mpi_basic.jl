#!/usr/bin/env sh
#SBATCH -N 2
#SBATCH -n 4
#SBATCH -o sl_mpi_basic_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
srun -n 4 julia --project -t 1 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#
using MPI
using ThreadPinning

MPI.Init()

nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)

sleep(0.3 * rank)
println("Rank $rank: ", getcpuids())

MPI.Finalize()
