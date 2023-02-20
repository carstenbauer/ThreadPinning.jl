#!/usr/bin/env sh
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task 25
#SBATCH -o sl_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00

srun -n 1 julia --project -t 25 check.jl pin
