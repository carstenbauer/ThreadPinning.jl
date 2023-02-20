#!/usr/bin/env sh
#SBATCH -N 2
#SBATCH -n 4
#SBATCH --ntasks-per-socket 1
#SBATCH --cpus-per-task 25
#SBATCH -o sl_hybrid_multinode_affinitymask_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
ml lang JuliaHPC
srun -n 4 julia --project -t 25 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#
using MPI
using ThreadPinning

MPI.Init()

nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)

pinthreads(:affinitymask)

sleep(0.3 * rank)
println("Rank $rank:")
println("\tHost: ", gethostname())
println("\tCPUs: ", getcpuids())

MPI.Finalize()
