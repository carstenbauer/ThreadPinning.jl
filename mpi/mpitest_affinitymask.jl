#!/usr/bin/env sh
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --cpus-per-task=5
#SBATCH --ntasks-per-socket=1
#SBATCH -o sl_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
srun julia --project -t 5 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#
using MPI
using ThreadPinning

MPI.Init()

rank = MPI.Comm_rank(MPI.COMM_WORLD)

pinthreads(:affinitymask)

sleep(0.3 * rank)
println("Rank $rank: ", getcpuids())

MPI.Finalize()
