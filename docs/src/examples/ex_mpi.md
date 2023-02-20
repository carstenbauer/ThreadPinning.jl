# MPI

## SLURM

In this section, we'll focus on MPI applications that run under SLURM (or a similar job scheduler). On most systems, the latter sets the affinity mask of the Julia processes (MPI ranks) based on the options set by the user (e.g. via `#SBATCH`). Consequently, one has to do little to nothing on the Julia side to achieve the desired pinning pattern.

### MPI only

If your MPI-parallel application is single threaded (i.e. one Julia thread per MPI rank), **you likely don't have to do anything on the Julia side** to pin the MPI ranks. Instead, you can just use the SLURM options.

**Multinode example, 1 MPI rank per socket:**

```julia
#!/usr/bin/env sh
#SBATCH -N 2 # two nodes
#SBATCH -n 4 # four MPI ranks in total
#SBATCH --ntasks-per-socket 1 # one MPI rank per socket
#SBATCH -o sl_mpi_multinode_%j.out
#SBATCH -A pc2-mitarbeiter
#SBATCH -p all
#SBATCH -t 00:02:00
#=
ml lang JuliaHPC # load Julia module (system specific!)
srun -n 4 julia --project -t 1 $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}')
exit
# =#
using MPI
using ThreadPinning

MPI.Init()
nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)
MPI.Barrier()
sleep(2*rank)
println("Rank $rank:")
println("\tHost: ", gethostname())
println("\tCPUs: ", getcpuids())
print_affinity_masks()
```

Output (manually cleaned up a bit):

```
Rank 0:
    Host: n2fpga19
    CPUs: [0]
1:   |1000000000000000000000000000000000000000000000000000000000000000|0000000000000000000000000000000000000000000000000000000000000000|

Rank 1:
    Host: n2fpga19
    CPUs: [64]
1:   |0000000000000000000000000000000000000000000000000000000000000000|1000000000000000000000000000000000000000000000000000000000000000|

Rank 2:
    Host: n2fpga33
    CPUs: [0]
1:   |1000000000000000000000000000000000000000000000000000000000000000|0000000000000000000000000000000000000000000000000000000000000000|

Rank 3:
    Host: n2fpga33
    CPUs: [64]
1:   |0000000000000000000000000000000000000000000000000000000000000000|1000000000000000000000000000000000000000000000000000000000000000|
```

### Hybrid: MPI + Threads

If your MPI-parallel application is multithreaded (i.e. multiple Julia threads per MPI rank), you can use [`pinthreads(:affinitymask)`](@ref) to pin Julia threads of each MPI rank according to the affinity mask set by SLURM (according to the user-specified options). If you don't use `pinthreads(:affinitymask)`, the Julia threads are only bound to a range of CPU-threads, they can migrate, and they can also overlap (occupy the same CPU-thread). See [Process Affinity Mask](@ref exaffinitymask) for more information.

**Multinode example, 1 MPI rank per socket, 25 threads per rank:**

```julia
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
pinthreads(:affinitymask)

MPI.Init()
nranks = MPI.Comm_size(MPI.COMM_WORLD)
rank = MPI.Comm_rank(MPI.COMM_WORLD)
MPI.Barrier()
sleep(2*rank)
println("Rank $rank:")
println("\tHost: ", gethostname())
println("\tCPUs: ", getcpuids())
```

Output:

```
Rank 0:
    Host: n2cn0853
    CPUs: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
Rank 1:
    Host: n2cn0853
    CPUs: [64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88]
Rank 2:
    Host: n2cn0854
    CPUs: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
Rank 3:
    Host: n2cn0854
    CPUs: [64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88]
```

## Manual

In this section, we describe how you can pin the Julia threads of your MPI ranks manually, that is without any "help" from an external affinity mask (e.g. as set by SLURM, see above).

TODO: [`pinthreads_mpi`](@ref)